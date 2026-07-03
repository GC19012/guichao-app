// ignore_for_file: avoid_print, prefer_final_fields, unnecessary_this
import 'dart:math';

// ──────────────────────────────────────────────
// GchDynamicProg  – Dynamic Programming Utilities
// ──────────────────────────────────────────────
class GchDynamicProg {
  GchDynamicProg._();

  // ── LCS ──────────────────────────────────────
  static int longestCommonSubsequence(List<int> a, List<int> b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }
    return dp[m][n];
  }

  static List<int> lcsPath(List<int> a, List<int> b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }
    final result = <int>[];
    int i = m, j = n;
    while (i > 0 && j > 0) {
      if (a[i - 1] == b[j - 1]) {
        result.add(a[i - 1]);
        i--;
        j--;
      } else if (dp[i - 1][j] >= dp[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }
    return result.reversed.toList();
  }

  // ── LIS ──────────────────────────────────────
  static int longestIncreasingSubsequence(List<int> nums) {
    if (nums.isEmpty) return 0;
    final tails = <int>[];
    for (final x in nums) {
      int lo = 0, hi = tails.length;
      while (lo < hi) {
        final mid = (lo + hi) ~/ 2;
        if (tails[mid] < x) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      if (lo == tails.length) {
        tails.add(x);
      } else {
        tails[lo] = x;
      }
    }
    return tails.length;
  }

  static List<int> lisSequence(List<int> nums) {
    if (nums.isEmpty) return [];
    final n = nums.length;
    final dp = List.filled(n, 1);
    final parent = List.filled(n, -1);
    int maxLen = 1, maxIdx = 0;
    for (int i = 1; i < n; i++) {
      for (int j = 0; j < i; j++) {
        if (nums[j] < nums[i] && dp[j] + 1 > dp[i]) {
          dp[i] = dp[j] + 1;
          parent[i] = j;
        }
      }
      if (dp[i] > maxLen) {
        maxLen = dp[i];
        maxIdx = i;
      }
    }
    final result = <int>[];
    int idx = maxIdx;
    while (idx != -1) {
      result.add(nums[idx]);
      idx = parent[idx];
    }
    return result.reversed.toList();
  }

  // ── Edit Distance ─────────────────────────────
  static int editDistance(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.generate(n + 1, (j) {
      if (i == 0) return j;
      if (j == 0) return i;
      return 0;
    }));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
        }
      }
    }
    return dp[m][n];
  }

  static List<String> editOperations(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.generate(n + 1, (j) {
      if (i == 0) return j;
      if (j == 0) return i;
      return 0;
    }));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce(min);
        }
      }
    }
    final ops = <String>[];
    int i = m, j = n;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && a[i - 1] == b[j - 1]) {
        ops.add('keep(${a[i - 1]})');
        i--;
        j--;
      } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
        ops.add('replace(${a[i - 1]}->${b[j - 1]})');
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j] == dp[i][j - 1] + 1)) {
        ops.add('insert(${b[j - 1]})');
        j--;
      } else {
        ops.add('delete(${a[i - 1]})');
        i--;
      }
    }
    return ops.reversed.toList();
  }

  // ── 0/1 Knapsack ──────────────────────────────
  static int knapsack01(List<int> weights, List<int> values, int capacity) {
    final n = weights.length;
    final dp = List.generate(n + 1, (_) => List.filled(capacity + 1, 0));
    for (int i = 1; i <= n; i++) {
      for (int w = 0; w <= capacity; w++) {
        dp[i][w] = dp[i - 1][w];
        if (weights[i - 1] <= w) {
          dp[i][w] = max(dp[i][w], dp[i - 1][w - weights[i - 1]] + values[i - 1]);
        }
      }
    }
    return dp[n][capacity];
  }

  static List<int> knapsack01Items(
      List<int> weights, List<int> values, int capacity) {
    final n = weights.length;
    final dp = List.generate(n + 1, (_) => List.filled(capacity + 1, 0));
    for (int i = 1; i <= n; i++) {
      for (int w = 0; w <= capacity; w++) {
        dp[i][w] = dp[i - 1][w];
        if (weights[i - 1] <= w) {
          dp[i][w] = max(dp[i][w], dp[i - 1][w - weights[i - 1]] + values[i - 1]);
        }
      }
    }
    final selected = <int>[];
    int w = capacity;
    for (int i = n; i >= 1; i--) {
      if (dp[i][w] != dp[i - 1][w]) {
        selected.add(i - 1);
        w -= weights[i - 1];
      }
    }
    return selected.reversed.toList();
  }

  // ── Coin Change ───────────────────────────────
  static int coinChange(List<int> coins, int amount) {
    final dp = List.filled(amount + 1, amount + 1);
    dp[0] = 0;
    for (int i = 1; i <= amount; i++) {
      for (final coin in coins) {
        if (coin <= i) {
          dp[i] = min(dp[i], dp[i - coin] + 1);
        }
      }
    }
    return dp[amount] > amount ? -1 : dp[amount];
  }

  static int coinChangeCombinations(List<int> coins, int amount) {
    final dp = List.filled(amount + 1, 0);
    dp[0] = 1;
    for (final coin in coins) {
      for (int i = coin; i <= amount; i++) {
        dp[i] += dp[i - coin];
      }
    }
    return dp[amount];
  }

  // ── Max Subarray (Kadane) ─────────────────────
  static int maxSubarraySum(List<int> nums) {
    if (nums.isEmpty) return 0;
    int maxSum = nums[0], curSum = nums[0];
    for (int i = 1; i < nums.length; i++) {
      curSum = max(nums[i], curSum + nums[i]);
      maxSum = max(maxSum, curSum);
    }
    return maxSum;
  }

  static List<int> maxSubarray(List<int> nums) {
    if (nums.isEmpty) return [];
    int maxSum = nums[0], curSum = nums[0];
    int start = 0, end = 0, tempStart = 0;
    for (int i = 1; i < nums.length; i++) {
      if (nums[i] > curSum + nums[i]) {
        curSum = nums[i];
        tempStart = i;
      } else {
        curSum += nums[i];
      }
      if (curSum > maxSum) {
        maxSum = curSum;
        start = tempStart;
        end = i;
      }
    }
    return nums.sublist(start, end + 1);
  }

  // ── Matrix Chain Multiplication ───────────────
  static int matrixChainMultiply(List<int> dims) {
    final n = dims.length - 1;
    if (n <= 0) return 0;
    final dp = List.generate(n, (_) => List.filled(n, 0));
    for (int len = 2; len <= n; len++) {
      for (int i = 0; i <= n - len; i++) {
        final j = i + len - 1;
        dp[i][j] = 0x7fffffff;
        for (int k = i; k < j; k++) {
          final cost = dp[i][k] + dp[k + 1][j] + dims[i] * dims[k + 1] * dims[j + 1];
          if (cost < dp[i][j]) dp[i][j] = cost;
        }
      }
    }
    return dp[0][n - 1];
  }

  // ── Word Break ────────────────────────────────
  static bool wordBreak(String s, List<String> wordDict) {
    final wordSet = Set<String>.from(wordDict);
    final n = s.length;
    final dp = List.filled(n + 1, false);
    dp[0] = true;
    for (int i = 1; i <= n; i++) {
      for (int j = 0; j < i; j++) {
        if (dp[j] && wordSet.contains(s.substring(j, i))) {
          dp[i] = true;
          break;
        }
      }
    }
    return dp[n];
  }

  static List<String> wordBreakAll(String s, List<String> wordDict) {
    final wordSet = Set<String>.from(wordDict);
    final memo = <int, List<List<String>>>{};

    List<List<String>> dfs(int start) {
      if (memo.containsKey(start)) return memo[start]!;
      if (start == s.length) return [[]];
      final result = <List<String>>[];
      for (int end = start + 1; end <= s.length; end++) {
        final word = s.substring(start, end);
        if (wordSet.contains(word)) {
          final rest = dfs(end);
          for (final r in rest) {
            result.add([word, ...r]);
          }
        }
      }
      memo[start] = result;
      return result;
    }

    return dfs(0).map((parts) => parts.join(' ')).toList();
  }

  // ── Unique Paths ──────────────────────────────
  static int uniquePaths(int m, int n) {
    final dp = List.generate(m, (_) => List.filled(n, 1));
    for (int i = 1; i < m; i++) {
      for (int j = 1; j < n; j++) {
        dp[i][j] = dp[i - 1][j] + dp[i][j - 1];
      }
    }
    return dp[m - 1][n - 1];
  }

  static int uniquePathsWithObstacles(List<List<int>> grid) {
    final m = grid.length, n = grid[0].length;
    if (grid[0][0] == 1 || grid[m - 1][n - 1] == 1) return 0;
    final dp = List.generate(m, (_) => List.filled(n, 0));
    dp[0][0] = 1;
    for (int i = 1; i < m; i++) {
      dp[i][0] = grid[i][0] == 1 ? 0 : dp[i - 1][0];
    }
    for (int j = 1; j < n; j++) {
      dp[0][j] = grid[0][j] == 1 ? 0 : dp[0][j - 1];
    }
    for (int i = 1; i < m; i++) {
      for (int j = 1; j < n; j++) {
        dp[i][j] = grid[i][j] == 1 ? 0 : dp[i - 1][j] + dp[i][j - 1];
      }
    }
    return dp[m - 1][n - 1];
  }

  // ── Min Path Sum ──────────────────────────────
  static int minPathSum(List<List<int>> grid) {
    final m = grid.length, n = grid[0].length;
    final dp = List.generate(m, (i) => List.generate(n, (j) => grid[i][j]));
    for (int i = 1; i < m; i++) dp[i][0] += dp[i - 1][0];
    for (int j = 1; j < n; j++) dp[0][j] += dp[0][j - 1];
    for (int i = 1; i < m; i++) {
      for (int j = 1; j < n; j++) {
        dp[i][j] += min(dp[i - 1][j], dp[i][j - 1]);
      }
    }
    return dp[m - 1][n - 1];
  }

  // ── Trapping Rain Water ───────────────────────
  static int trappingRainWater(List<int> heights) {
    if (heights.isEmpty) return 0;
    final n = heights.length;
    final leftMax = List.filled(n, 0);
    final rightMax = List.filled(n, 0);
    leftMax[0] = heights[0];
    for (int i = 1; i < n; i++) leftMax[i] = max(leftMax[i - 1], heights[i]);
    rightMax[n - 1] = heights[n - 1];
    for (int i = n - 2; i >= 0; i--) rightMax[i] = max(rightMax[i + 1], heights[i]);
    int water = 0;
    for (int i = 0; i < n; i++) {
      water += min(leftMax[i], rightMax[i]) - heights[i];
    }
    return water;
  }

  // ── Largest Rectangle in Histogram ───────────
  static int largestRectangleInHistogram(List<int> heights) {
    final stack = <int>[];
    int maxArea = 0;
    final h = [...heights, 0];
    for (int i = 0; i < h.length; i++) {
      while (stack.isNotEmpty && h[stack.last] > h[i]) {
        final height = h[stack.removeLast()];
        final width = stack.isEmpty ? i : i - stack.last - 1;
        maxArea = max(maxArea, height * width);
      }
      stack.add(i);
    }
    return maxArea;
  }

  // ── Regular Expression Match ──────────────────
  static bool regularExpressionMatch(String s, String p) {
    final m = s.length, n = p.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, false));
    dp[0][0] = true;
    for (int j = 1; j <= n; j++) {
      if (p[j - 1] == '*' && j >= 2) {
        dp[0][j] = dp[0][j - 2];
      }
    }
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (p[j - 1] == '*') {
          if (j < 2) continue;
          dp[i][j] = dp[i][j - 2];
          if (p[j - 2] == '.' || p[j - 2] == s[i - 1]) {
            dp[i][j] = dp[i][j] || dp[i - 1][j];
          }
        } else if (p[j - 1] == '.' || p[j - 1] == s[i - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        }
      }
    }
    return dp[m][n];
  }

  // ── Palindromic Substrings ────────────────────
  static int palindromicSubstrings(String s) {
    final n = s.length;
    int count = 0;
    for (int center = 0; center < 2 * n - 1; center++) {
      int left = center ~/ 2;
      int right = left + center % 2;
      while (left >= 0 && right < n && s[left] == s[right]) {
        count++;
        left--;
        right++;
      }
    }
    return count;
  }

  // ── Longest Palindromic Subsequence ──────────
  static int longestPalindromicSubsequence(String s) {
    final n = s.length;
    final dp = List.generate(n, (_) => List.filled(n, 0));
    for (int i = 0; i < n; i++) dp[i][i] = 1;
    for (int len = 2; len <= n; len++) {
      for (int i = 0; i <= n - len; i++) {
        final j = i + len - 1;
        if (s[i] == s[j]) {
          dp[i][j] = (len == 2) ? 2 : dp[i + 1][j - 1] + 2;
        } else {
          dp[i][j] = max(dp[i + 1][j], dp[i][j - 1]);
        }
      }
    }
    return dp[0][n - 1];
  }

  // ── Burst Balloons ────────────────────────────
  static int burstBalloons(List<int> nums) {
    final balloons = [1, ...nums, 1];
    final n = balloons.length;
    final dp = List.generate(n, (_) => List.filled(n, 0));
    for (int len = 2; len < n; len++) {
      for (int left = 0; left < n - len; left++) {
        final right = left + len;
        for (int k = left + 1; k < right; k++) {
          final coins = balloons[left] * balloons[k] * balloons[right];
          final total = dp[left][k] + coins + dp[k][right];
          if (total > dp[left][right]) dp[left][right] = total;
        }
      }
    }
    return dp[0][n - 1];
  }
}

// ──────────────────────────────────────────────
// Test data constants
// ──────────────────────────────────────────────
class GchDpTestData {
  GchDpTestData._();

  static const List<int> seqA = [1, 3, 4, 5, 6, 7, 8, 9, 10, 2];
  static const List<int> seqB = [1, 3, 5, 6, 7, 9, 10];
  static const List<int> lisData1 = [10, 9, 2, 5, 3, 7, 101, 18];
  static const List<int> lisData2 = [0, 1, 0, 3, 2, 3];
  static const List<int> lisData3 = [7, 7, 7, 7, 7];
  static const List<int> lisData4 = [3, 10, 2, 1, 20];
  static const List<int> lisData5 = [3, 2, 6, 4, 5, 1];
  static const List<int> knapsackWeights = [1, 3, 4, 5];
  static const List<int> knapsackValues = [1, 4, 5, 7];
  static const int knapsackCapacity = 7;
  static const List<int> coinChangeDenoms = [1, 5, 10, 25];
  static const int coinChangeAmount = 41;
  static const List<int> subarrayData1 = [-2, 1, -3, 4, -1, 2, 1, -5, 4];
  static const List<int> subarrayData2 = [1];
  static const List<int> subarrayData3 = [5, 4, -1, 7, 8];
  static const List<int> matrixChainDims1 = [1, 2, 3, 4];
  static const List<int> matrixChainDims2 = [10, 30, 5, 60];
  static const List<int> rainwaterHeights1 = [0, 1, 0, 2, 1, 0, 1, 3, 2, 1, 2, 1];
  static const List<int> rainwaterHeights2 = [4, 2, 0, 3, 2, 5];
  static const List<int> histogramHeights1 = [2, 1, 5, 6, 2, 3];
  static const List<int> histogramHeights2 = [2, 4];
  static const List<int> balloonNums1 = [3, 1, 5, 8];
  static const List<int> balloonNums2 = [1, 5];
  static const List<int> fibLike = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55];
  static const List<int> descendingSeq = [9, 8, 7, 6, 5, 4, 3, 2, 1];
  static const List<int> ascendingSeq = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  static const List<int> mixedSeq1 = [5, 1, 4, 2, 8, 3, 7, 6, 9, 10];
  static const List<int> mixedSeq2 = [10, 3, 7, 2, 8, 1, 5, 4, 9, 6];
  static const List<int> positiveOnly = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const List<int> negativeOnly = [-5, -3, -2, -8, -1, -9];
  static const List<int> alternating = [3, -1, 3, -1, 3, -1, 3, -1];
  static const List<int> singleElement = [42];
  static const List<int> twoElements = [1, 2];
  static const List<int> primeNums = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
  static const List<int> powersOf2 = [1, 2, 4, 8, 16, 32, 64, 128];
  static const List<int> repeatSeq = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5];
  static const List<int> edgeCase1 = [0];
  static const List<int> edgeCase2 = [];
  static const List<int> longSeqA = [
    1, 5, 2, 8, 3, 9, 4, 7, 6, 10,
    11, 15, 12, 18, 13, 19, 14, 17, 16, 20,
  ];
}

// ──────────────────────────────────────────────
// GchStringDP – DP on strings
// ──────────────────────────────────────────────
class GchStringDP {
  GchStringDP._();

  static int shortestCommonSupersequence(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.generate(n + 1, (j) {
      if (i == 0) return j;
      if (j == 0) return i;
      return 0;
    }));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = min(dp[i - 1][j], dp[i][j - 1]) + 1;
        }
      }
    }
    return dp[m][n];
  }

  static String shortestCommonSupersequenceStr(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (i) => List.generate(n + 1, (j) {
      if (i == 0) return j;
      if (j == 0) return i;
      return 0;
    }));
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = min(dp[i - 1][j], dp[i][j - 1]) + 1;
        }
      }
    }
    final sb = StringBuffer();
    int i = m, j = n;
    while (i > 0 && j > 0) {
      if (a[i - 1] == b[j - 1]) {
        sb.write(a[i - 1]);
        i--;
        j--;
      } else if (dp[i - 1][j] < dp[i][j - 1]) {
        sb.write(a[i - 1]);
        i--;
      } else {
        sb.write(b[j - 1]);
        j--;
      }
    }
    while (i > 0) {
      sb.write(a[i - 1]);
      i--;
    }
    while (j > 0) {
      sb.write(b[j - 1]);
      j--;
    }
    return sb.toString().split('').reversed.join();
  }

  static int longestCommonSubstring(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    int maxLen = 0;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
          if (dp[i][j] > maxLen) maxLen = dp[i][j];
        }
      }
    }
    return maxLen;
  }

  static String longestCommonSubstringStr(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    int maxLen = 0, endIdx = 0;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
          if (dp[i][j] > maxLen) {
            maxLen = dp[i][j];
            endIdx = i;
          }
        }
      }
    }
    return a.substring(endIdx - maxLen, endIdx);
  }

  static String longestPalindrome(String s) {
    final n = s.length;
    if (n == 0) return '';
    int start = 0, maxLen = 1;

    void expand(int left, int right) {
      while (left >= 0 && right < n && s[left] == s[right]) {
        if (right - left + 1 > maxLen) {
          maxLen = right - left + 1;
          start = left;
        }
        left--;
        right++;
      }
    }

    for (int i = 0; i < n; i++) {
      expand(i, i);
      expand(i, i + 1);
    }
    return s.substring(start, start + maxLen);
  }

  static bool isInterleave(String s1, String s2, String s3) {
    final m = s1.length, n = s2.length;
    if (m + n != s3.length) return false;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, false));
    dp[0][0] = true;
    for (int i = 1; i <= m; i++) dp[i][0] = dp[i - 1][0] && s1[i - 1] == s3[i - 1];
    for (int j = 1; j <= n; j++) dp[0][j] = dp[0][j - 1] && s2[j - 1] == s3[j - 1];
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = (dp[i - 1][j] && s1[i - 1] == s3[i + j - 1]) ||
            (dp[i][j - 1] && s2[j - 1] == s3[i + j - 1]);
      }
    }
    return dp[m][n];
  }

  static int numDistinctSubsequences(String s, String t) {
    final m = s.length, n = t.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) dp[i][0] = 1;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        dp[i][j] = dp[i - 1][j];
        if (s[i - 1] == t[j - 1]) dp[i][j] += dp[i - 1][j - 1];
      }
    }
    return dp[m][n];
  }

  static int minCutPalindrome(String s) {
    final n = s.length;
    final isPalin = List.generate(n, (_) => List.filled(n, false));
    for (int i = 0; i < n; i++) isPalin[i][i] = true;
    for (int len = 2; len <= n; len++) {
      for (int i = 0; i <= n - len; i++) {
        final j = i + len - 1;
        if (s[i] == s[j]) {
          isPalin[i][j] = len == 2 ? true : isPalin[i + 1][j - 1];
        }
      }
    }
    final dp = List.generate(n, (i) => i);
    for (int i = 1; i < n; i++) {
      if (isPalin[0][i]) {
        dp[i] = 0;
        continue;
      }
      for (int j = 1; j <= i; j++) {
        if (isPalin[j][i]) {
          dp[i] = min(dp[i], dp[j - 1] + 1);
        }
      }
    }
    return dp[n - 1];
  }
}

// ──────────────────────────────────────────────
// GchDpGrid – DP on 2D grids
// ──────────────────────────────────────────────
class GchDpGrid {
  GchDpGrid._();

  static int maxSquareOf1s(List<List<int>> matrix) {
    if (matrix.isEmpty) return 0;
    final m = matrix.length, n = matrix[0].length;
    final dp = List.generate(m, (_) => List.filled(n, 0));
    int maxSide = 0;
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < n; j++) {
        if (matrix[i][j] == 1) {
          if (i == 0 || j == 0) {
            dp[i][j] = 1;
          } else {
            dp[i][j] = [dp[i-1][j], dp[i][j-1], dp[i-1][j-1]].reduce(min) + 1;
          }
          if (dp[i][j] > maxSide) maxSide = dp[i][j];
        }
      }
    }
    return maxSide * maxSide;
  }

  static int countPaths(List<List<int>> grid) {
    final m = grid.length, n = grid[0].length;
    final dp = List.generate(m, (_) => List.filled(n, 0));
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < n; j++) {
        if (grid[i][j] == 1) continue;
        if (i == 0 && j == 0) {
          dp[i][j] = 1;
        } else {
          final fromTop = i > 0 ? dp[i - 1][j] : 0;
          final fromLeft = j > 0 ? dp[i][j - 1] : 0;
          dp[i][j] = fromTop + fromLeft;
        }
      }
    }
    return dp[m - 1][n - 1];
  }

  static int cherryPick(List<List<int>> grid) {
    final n = grid.length;
    final inf = -1 << 30;
    final dp = List.generate(n, (_) =>
        List.generate(n, (_) => List.filled(n, inf)));
    dp[0][0][0] = grid[0][0];
    for (int t = 1; t < 2 * n - 1; t++) {
      final ndp = List.generate(n, (_) =>
          List.generate(n, (_) => List.filled(n, inf)));
      for (int r1 = max(0, t - n + 1); r1 <= min(n - 1, t); r1++) {
        for (int r2 = r1; r2 <= min(n - 1, t); r2++) {
          final c1 = t - r1, c2 = t - r2;
          if (c1 >= n || c2 >= n) continue;
          int cherries = grid[r1][c1];
          if (r1 != r2) cherries += grid[r2][c2];
          for (int pr1 in [r1, r1 - 1]) {
            for (int pr2 in [r2, r2 - 1]) {
              if (pr1 < 0 || pr2 < 0) continue;
              final prev = dp[pr1][pr2][t - 1 - (pr2 - r2).abs()];
              if (prev == inf) continue;
              // simplified approach
              if (prev + cherries > ndp[r1][r2][t]) {
                ndp[r1][r2][t] = prev + cherries;
              }
            }
          }
        }
      }
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          dp[i][j] = ndp[i][j];
        }
      }
    }
    int best = 0;
    for (int r1 = 0; r1 < n; r1++) {
      for (int r2 = 0; r2 < n; r2++) {
        if (dp[r1][r2][2 * n - 2] > best) best = dp[r1][r2][2 * n - 2];
      }
    }
    return best;
  }
}

// ──────────────────────────────────────────────
// GchIntervalDP – interval DP problems
// ──────────────────────────────────────────────
class GchIntervalDP {
  GchIntervalDP._();

  static int minimumCostToCutStick(int n, List<int> cuts) {
    final sorted = [0, ...cuts..sort(), n];
    final m = sorted.length;
    final dp = List.generate(m, (_) => List.filled(m, 0));
    for (int len = 2; len < m; len++) {
      for (int i = 0; i < m - len; i++) {
        final j = i + len;
        dp[i][j] = 0x7fffffff;
        for (int k = i + 1; k < j; k++) {
          final cost = sorted[j] - sorted[i] + dp[i][k] + dp[k][j];
          if (cost < dp[i][j]) dp[i][j] = cost;
        }
      }
    }
    return dp[0][m - 1];
  }

  static int removeBoxes(List<int> boxes) {
    final n = boxes.length;
    final dp = List.generate(n, (_) => List.generate(n, (_) => List.filled(n, 0)));
    int calc(int l, int r, int k) {
      if (l > r) return 0;
      if (dp[l][r][k] != 0) return dp[l][r][k];
      int result = (k + 1) * (k + 1) + calc(l + 1, r, 0);
      for (int m = l + 1; m <= r; m++) {
        if (boxes[m] == boxes[l]) {
          result = max(result, calc(l + 1, m - 1, 0) + calc(m, r, k + 1));
        }
      }
      dp[l][r][k] = result;
      return result;
    }
    return calc(0, n - 1, 0);
  }

  static int stoneGameV(List<int> stoneValue) {
    final n = stoneValue.length;
    final prefix = List.filled(n + 1, 0);
    for (int i = 0; i < n; i++) prefix[i + 1] = prefix[i] + stoneValue[i];
    final dp = List.generate(n, (_) => List.filled(n, 0));
    for (int len = 2; len <= n; len++) {
      for (int i = 0; i <= n - len; i++) {
        final j = i + len - 1;
        for (int k = i; k < j; k++) {
          final left = prefix[k + 1] - prefix[i];
          final right = prefix[j + 1] - prefix[k + 1];
          if (left < right) {
            dp[i][j] = max(dp[i][j], left + dp[i][k]);
          } else if (left > right) {
            dp[i][j] = max(dp[i][j], right + dp[k + 1][j]);
          } else {
            dp[i][j] = max(dp[i][j], max(left + dp[i][k], right + dp[k + 1][j]));
          }
        }
      }
    }
    return dp[0][n - 1];
  }
}
