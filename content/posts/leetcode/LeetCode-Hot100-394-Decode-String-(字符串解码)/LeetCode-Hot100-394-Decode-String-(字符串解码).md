---
title: "LeetCode Hot100 394 : Decode String (字符串解码)"
date: "2026-11-24T16:25:20+08:00"
draft: false
url: "/posts/leetcode/LeetCode-Hot100-394-Decode-String-(字符串解码)/"
categories: ["leetcode"]
tags: ["hot100", "栈", "字符串"]
summary: ""
cover:
  image: "cover.png"
  alt: ""
---

# LeetCode Hot100 394 : Decode String (字符串解码)

题目链接 : [LeetCode Hot100 394 : Decode String](https://leetcode.cn/problems/decode-string/?envType=problem-list-v2&envId=2cktkvj)



## 题目理解

用Example2 举例:

Input:

```python
s = "3[a2[c]]"
```

Output: "accaccacc"

题目不难理解, 关键是对字符串的应用.

​		用一个stack进行存储,  遇到`"]"` , 就重新组织栈中的内容, 用上面的例子, 遇到第一个`"]"` 的时候, 栈中的 `2[c` 实际上要变成 `cc` , 然后接到`a` 的后面, 成为 `acc` ,基本上就是这个逻辑.

​		我们需要对字符串进行拼接, 先自己写一下试试:

```python
class Solution(object):
    def decodeString(self, s):
        """
        :type s: str
        :rtype: str
        """
        stack = []
        for ch in s:
            if ch != ']':
                stack.append(ch)
                # 遇到了右括号, 取出来栈顶元素, 组成新的字符串, 直到遇到'['
            else:
                tmp = ""
                while stack[-1] != '[':
                    tmp = stack.pop() + tmp # 这里不能写反, 新出来的保存在左边
                # 遇到了左括号
                stack.pop()
                # 接下来是数字
                cnt = ""
                while stack and stack[-1].isdigit(): # 这里如果是空队列, while stack[-1] 会直接抛"list index out of range", 因为"[]" 是没有-1 的
                    cnt = stack.pop() + cnt
                tmp = tmp * int(cnt)
                # 把现在的tmp拼接到stack中
                stack.append(tmp)
                
        # 最后结束,得到了栈中的元素, 逐个取出来
        ans = ""
        while stack:
            ans = stack.pop() + ans

        return ans
            
```



Ok, 解决, 好久之前的一道题, 圆满落幕! 
