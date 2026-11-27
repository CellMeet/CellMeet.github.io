---
title: "Go语言接口: 鸭子类型与隐式实现"
date: "2026-11-26T16:27:01+08:00"
draft: false
url: "/posts/golang/Go语言接口-鸭子类型与隐式实现/"
categories: ["golang"]
tags: ["golang", "duke type", "interface"]
summary: ""
cover:
  image: "go.png"
  alt: ""
---

# Go语言接口: 鸭子类型与隐式实现

## 前言

从Java 开始学习Go, 遇到Go 的接口(interface)设计, 感觉到Go语言接口机制的精妙. 具体例子如下:

定义struct 类型NormalTruck:

```go
type NormalTruck struct {
	id    string
	cargo int
}
```

定义接口 Truck(表示Truck 的行为):

```go
type NormalTruck struct {
	id    string
	cargo int
}
```

在不使用`implements` 关键字的情况下, NormalTruck可以直接使用 Truck的方法:

```go
func (t NormalTruck) LoadCargo() error {
	return nil
}
```

## 正文

这里Go 语言实现了Truck 的接口方法, 但是没有使用implements 接口声明. 事实上, 这和Go语言的**"鸭子类型"**(Duck) 接口设计哲学有关. 具体来说, 就是:**"它走起来像鸭子、叫起来像鸭子，那它就是鸭子"** .  应用到Go 的接口上, 就是: 

<center><b>如果一个类型拥有接口所要求的所有方法，那它就自动实现了该接口<b></center>

再举一个例子:

