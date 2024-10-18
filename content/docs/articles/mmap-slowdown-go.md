---
title: mmap 让 Go 程序更慢
description: 本文介绍了 mmap 和 缺页中断的原理和概念，又结合 Go 语言运行时机制，来分析为什么 mmap 在 Go 程序里不建议使用。
---

> 该文章是 VictoriaMetrics 作者写的，
> 原文地址：
> https://valyala.medium.com/mmap-in-go-considered-harmful-d92a25cb161d

你有在 Go 程序中使用 `syscall.Mmap` 吗？答案很可能是肯定的，只是你不知道而已。因为你的程序直接或间接的依赖包会使用 `syscall.Mmap`，毕竟众所周知的：mmap 要比常规的 I/O 操作快。我们现在来看一下到底是不是这样。

## 什么是 mmap?

[mmap](http://man7.org/linux/man-pages/man2/mmap.2.html) 是一个系统调用，将文件内容直接映射到内存地址空间。mmap 之后，你就可以像访问内存一样对文件内容进行读写。这样就不需要使用比较重的系统调用（如[`read`](http://man7.org/linux/man-pages/man2/read.2.html),[`write`](http://man7.org/linux/man-pages/man2/write.2.html)）去对文件内容进行读写了。

使用系统调用操作文件，进程会在内核态和用户态之间频繁切换，而且数据还要在用户态和内核态之间来回拷贝。而 mmap 后，整个数据的读写都在用户态完成，不会进入内核态，同时也少了一次数据拷贝。  
是不是觉得很完美？其实不是的。

## mmap 是如何工作的？

程序访问 mmap 返回的内存地址空间会发生什么？有两种场景：

1. 要访问的地址空间，指向的是已经在内存中的热数据。也就是大家常说的 [Page Cache](https://www.thomas-krenn.com/en/wiki/Linux_Page_Cache_Basics)。这时 mmap 确实是要比常规的系统调用`read`/`write`快。
2. 要访问的地址空间，是没有在 Page Cache 中的冷数据。这时操作系统会触发[缺页中断](https://en.wikipedia.org/wiki/Page_fault#Major)，进入内核态，将要访问的数据块拷贝到 Page Cache，然后再返回到用户态执行用户代码。整个过程对程序是不可见的，程序只是照常访问一个内存地址空间而已；但它的代价却是非常昂贵的，因为访问冷数据比访问热数据慢[10万倍](https://gist.github.com/jboner/2841832)）。

你可能会说，那正常的使用`read`/`write` 访问冷数据，也会有同样的问题；也会触发缺页中断，唯一不同的是把内存访问换成了一个系统调用。

的确是这样，但是让我们来看一下 Go 的运行时机制。

## Go 中的 mmap

Go 的 [goroutine 是运行在 OS threads（操作系统线程）之上](https://github.com/golang/go/blob/a361ef36af4812815c02dd026c4672837442bf44/src/runtime/proc.go#L16)的。最多可以有[`GOMAXPROCS`](https://golang.org/pkg/runtime/#GOMAXPROCS)个 goroutine **并行**的运行在 OS thread 上。其他就绪的 goroutine 会一直等待，直到运行中的 goroutine 发生了阻塞、出让、或者系统调用。goroutine 会因为 `I/O`、`channel`、`mutex` 而阻塞，或因为函数调用、内存分配、调用[`runtime.Gosched`](https://golang.org/pkg/runtime/#Gosched)而出让。**但 Goroutine 并不会因为缺页中断而阻塞！**

**再强调一次，goroutine 不会因为缺页中断而发生阻塞或出让，因为它对 Go 运行时是不可见的**。  
那当一个 goroutine 通过`mmap`访问到冷数据时，会发生什么呢？它会让你的程序卡在那里很长很长时间。在这期间，它还是会持续占用你的 OS thread，所以其他就绪的 goroutine 因为受到`GOMAXPROCS`的限制，只能排队。  
这就导致 CPU 的利用率很低。如果`GOMAXPROCS`个 goroutine 同时访问`mmap`文件的冷数据，会发生什么？整个程序会彻底地 Hang 住，直到 OS 完成了这些 goroutine 触发的缺页中断。

## 如何检测出 Go 程序是不是被缺页中断卡住了？

监控请求延迟和 CPU 利用率：
- 在程序卡住的期间，所有请求的耗时会整体升高。
- CPU 的`user`会下降，因为这期间程序卡住了，基本不做任何事情。
- CPU 的`sys`和`iowait`和会升高，因为发生了缺页中断。

## 如何解决这个问题？
- 增加`GOMAXPROCS`为 CPU 核数的`N`倍。也就是当 OS Thread 因为缺页中断被一个 goroutine 霸占的时候，还可以有其他更多的 OS Thread 可以用来执行就绪的 goroutine。但这个代价是，没有发生缺页中断时，CPU 利用率会更高，因为一个 cpu core 要同时处理多个 OS Thread 了。
- 通过`cgo`访问被`mmap`的数据。Go 会创建额外的 OS thread 来处理 cgo 调用。它的代价也一样是 CPU 利用率较高，因为 [cgo 调用是昂贵的](https://dave.cheney.net/2016/01/18/cgo-is-not-go)。
- 不要在 Go 程序里使用 `mmap`。


## 很多 Go 程序中都使用了 mmap，而且没人在意

这些程序在程序访问 page cache 中的数据时，是没有任何问题的。page cache 的大小受内存大小限制。所以这些程序只有在被 `mmap` 的文件很大时（超出内存大小），才会出现卡住的现象。在低负载场景，或者存储设备较快时（比如 SSD），不太容易注意到程序出现卡顿。

当 `mmap` 文件小于内存空间时，以下场景也会出现卡顿：

- 首次访问`mmap`文件，此时数据还没有加载到 Page Cache 中。这种情况一般发生在程序刚启动时的预热阶段，常见于 db 的 bootstrap。此时不只是访问到`mmap`文件中的数据的请求会变慢，整个程序所有逻辑都会变慢。
- 访问的数据块已经从 Page Cache 中驱逐出去的数据。驱逐可能是由系统上的其他进程导致的，毕竟 Page Cache 是整个系统共享的。比如，你在系统上执行`grep`命令去处理一个很大的日志文件，它会大量使用 Page Cache，进而驱逐掉其他进程在 Page Cache 中的数据。

## 结论

尽量避免在 Go 程序中使用 mmap，因为它可能让你的程序 Hang 住。 