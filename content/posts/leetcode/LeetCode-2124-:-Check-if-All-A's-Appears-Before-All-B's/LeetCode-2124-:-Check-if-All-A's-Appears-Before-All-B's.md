---
title: "LeetCode 2124 : Check if All A's Appears Before All B's"
date: "2026-11-22T08:35:55+08:00"
draft: false
url: "/posts/leetcode/LeetCode-2124-:-Check-if-All-A's-Appears-Before-All-B's/"
categories: ["leetcode"]
tags: []
summary: ""
cover:
  image: "leetcode.jpg"
  alt: ""
---



力扣2124, 难度为easy, 思路很简单： 判断是否出现了"ba" 的情况， 如果没有，那就返回True, 否则返回False

```python
class Solution:
    def checkString(self, s: string) -> bool:
        for i in range(1, len(s)):
            if s[i] == 'a' and s[i-1] == 'b':
                return False
        
        return True
```



```python
class Solution:
    def checkString(self, s: string) -> bool:
        return s.find("ba") == -1
```



```c++
class Solution{
public:
    bool checkString(string s) {
        return s.find("ba") == string::npos;
    }
};
```

注：

​		`string :: npos` 是find、rfind 、 find_first_of 这些函数，__找不到__ 的时候都返回 `npos` 。



```go
func checkString(s string) bool {
    return !strings.Contains(s, "ba")
}
```

