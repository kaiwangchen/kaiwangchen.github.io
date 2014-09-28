---
layout: post
title: Windows Server 2008 R2 SP1 语言切换
author: kc
tags:
- windows server 2008 R2
- 多语言支持
wordpress_id: 442
wordpress_url: http://kaiwangchen.com/blog/?p=442
date: 2014-04-15 12:05:55 +0800
---

## 背景介绍

[Windows Server 2008 R2][1] SP1 基于 Windows NT 6.1 核心，是 Windows 7 的服务器版。最简操作系统由语言无关的二进制文件和至少一个语言包构成。如[阿里云][2]提供的 Windows Server 2008 R2 SP1 64-bit 简体中文版镜像中附带的是简体中文语言包。[Windows Server 2008 R2 SP1 的多语言支持][3]分为两种，一种称为“部分本地化”，大部分语言版本是部分本地化的，如简体中文语言包是一个增量包，其基础是英文语言包；另一种称为“完整本地化”，只有少数几种语言版本实现了完整本地化，如英文和日文等。<!--more-->英语可以作为基础语言包和完整本地化包，不难理解二者是会有一些重合的。

从技术角度来看，不同语言版本的 Windows Server 2008 R2 SP1 操作系统，其区别仅在于用户界面元素，语言切换可以通过安装“基础语言包+部分本地化语言包”或者“完整本地化的语言包”，然后在控制面板“更改显示语言”里完成，操作系统可能需要重启才能完成语言切换。

## 操作步骤

Windows Server 2008 R2 SP1 64-bit 从简体中文 (A) 切换到其他语言 (B) 的操作步骤

1.  到[微软官网][4]上查看语言 B 的的本地化类型是“部分本地化”还是“完整本地化”

2.  下载基础语言包和部分本地化语言包，或者完整本地化的语言包。不过微软是统一提供一个 [2\.7GB 的 ISO 镜像][5]，里面包含了所有语言包，下载后提取语言 B 的版本即可

3.  在控制面板“更改显示语言”里，点“安装/删除”语言，定位到第 2 步里提取出来的语言 B 目录

4.  在控制面板“更改显示语言”里选择目标语言 B ，确定后重启系统

## English Readers

[Windows Server 2008 R2][1] SP1 is built on Windows NT 6.1, as the server-variant of Windows 7. Contains at least one language pack and the language-neutral binaries that make up the core operating system. The Windows Server 2008 R2 SP1 64-bit Simplified Chinese image provided by [Aliyun][2] ships Simplified Chinese as default language, which is a partially localized version with English as base language, while English version is one of the fully localized versions. Technically they differ only in certain part of UI, and the difference should be eliminated with a English language pack installed covering that part. For full description, please refer to [Understanding Multilingual Deployments][3] and [Available Language Packs][4].

I have verified that the operating system can switch to English UI after reboot with English language pack installed. The language pack (292MB) can be retrieved from Windows Server 2008 R2 Service Pack 1 Multilingual User Interface Language Packs ([2\.7GB ISO image][5]).

 [1]: http://en.wikipedia.org/wiki/Windows_Server_2008_R2
 [2]: http://www.aliyun.com/product/ecs/
 [3]: http://technet.microsoft.com/en-us/library/dd744336%28WS.10%29.aspx
 [4]: http://technet.microsoft.com/en-us/library/dd744369%28v=ws.10%29.aspx
 [5]: http://www.microsoft.com/en-us/download/details.aspx?id=2634
