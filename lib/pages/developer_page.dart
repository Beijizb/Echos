import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/developer_mode_service.dart';
import '../services/music_service.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';
import '../services/playback_state_service.dart';
import '../services/player_service.dart';
import '../utils/theme_manager.dart';
import 'lx_music_runtime_test_page.dart';

/// 开发者页面
class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _fluentTabIndex = 0;
  int _fluentAdminTabIndex = 0;
  int _cupertinoTabIndex = 0; // iOS 标签页索引

  // 日志过滤
  Set<LogLevel> _selectedLogLevels = LogLevel.values.toSet();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 监听日志更新，自动滚动到底部
    DeveloperModeService().addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logScrollController.dispose();
    _searchController.dispose();
    DeveloperModeService().removeListener(_scrollToBottom);
    super.dispose();
  }

  void _scrollToBottom() {
    if (_logScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_logScrollController.hasClients) {
          _logScrollController.animateTo(
            _logScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 检查是否启用 Fluent UI 主题
    if (Platform.isWindows && ThemeManager().isFluentFramework) {
      return _buildFluentPage(context);
    }

    // 检查是否启用 Cupertino 主题
    if ((Platform.isIOS || Platform.isAndroid) && ThemeManager().isCupertinoFramework) {
      return _buildCupertinoPage(context);
    }

    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.code, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text('开发者模式'),
          ],
        ),
        backgroundColor: colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bug_report), text: '日志'),
            Tab(icon: Icon(Icons.storage), text: '数据'),
            Tab(icon: Icon(Icons.settings), text: '设置'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            tooltip: '退出开发者模式',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('退出开发者模式'),
                  content: const Text('确定要退出开发者模式吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    FilledButton(
                      onPressed: () {
                        DeveloperModeService().disableDeveloperMode();
                        Navigator.pop(context);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogTab(),
          _buildDataTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  /// 构建日志标签页
  Widget _buildLogTab() {
    return AnimatedBuilder(
      animation: DeveloperModeService(),
      builder: (context, child) {
        final allLogs = DeveloperModeService().logEntries;

        // 过滤日志
        var filteredLogs = allLogs.where((log) => _selectedLogLevels.contains(log.level)).toList();

        // 搜索过滤
        if (_searchKeyword.isNotEmpty) {
          filteredLogs = filteredLogs.where((log) =>
            log.message.toLowerCase().contains(_searchKeyword.toLowerCase()) ||
            (log.data?.toString().toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false)
          ).toList();
        }

        return Column(
          children: [
            // 搜索栏
            Container(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索日志...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchKeyword.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchKeyword = '';
                            });
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchKeyword = value;
                  });
                },
              ),
            ),

            // 过滤器
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildLogLevelChip(LogLevel.debug, '🔍 调试', filteredLogs),
                  _buildLogLevelChip(LogLevel.info, 'ℹ️ 信息', filteredLogs),
                  _buildLogLevelChip(LogLevel.warning, '⚠️ 警告', filteredLogs),
                  _buildLogLevelChip(LogLevel.error, '❌ 错误', filteredLogs),
                  _buildLogLevelChip(LogLevel.api, '🌐 API', filteredLogs),
                ],
              ),
            ),

            // 工具栏
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Text(
                    '共 ${filteredLogs.length}/${allLogs.length} 条日志',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: '复制全部',
                    onPressed: () {
                      final text = filteredLogs.map((e) => e.toString()).join('\n');
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制到剪贴板')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: '清除日志',
                    onPressed: () {
                      DeveloperModeService().clearLogs();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 日志列表
            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Text(
                        _searchKeyword.isNotEmpty ? '没有匹配的日志' : '暂无日志',
                      ),
                    )
                  : ListView.builder(
                      controller: _logScrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return _buildLogItem(log);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// 构建日志级别筛选芯片
  Widget _buildLogLevelChip(LogLevel level, String label, List<LogEntry> filteredLogs) {
    final isSelected = _selectedLogLevels.contains(level);
    final count = filteredLogs.where((log) => log.level == level).length;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedLogLevels.add(level);
            } else {
              _selectedLogLevels.remove(level);
            }
          });
        },
      ),
    );
  }

  /// 构建单个日志项
  Widget _buildLogItem(LogEntry log) {
    Color levelColor;
    switch (log.level) {
      case LogLevel.debug:
        levelColor = Colors.grey;
        break;
      case LogLevel.info:
        levelColor = Colors.blue;
        break;
      case LogLevel.warning:
        levelColor = Colors.orange;
        break;
      case LogLevel.error:
        levelColor = Colors.red;
        break;
      case LogLevel.api:
        levelColor = Colors.green;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: levelColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                log.levelIcon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 4),
              Text(
                log.formattedTime,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: levelColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  log.message,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (log.data != null && log.data!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
              child: SelectableText(
                log.data.toString(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
          ],
        );
      },
    );
  }

  /// 构建数据标签页
  Widget _buildDataTab() {
    return AnimatedBuilder(
      animation: AdminService(),
      builder: (context, child) {
        if (!AdminService().isAuthenticated) {
          return _buildAdminLogin();
        } else {
          return _buildAdminPanel();
        }
      },
    );
  }

  /// 构建管理员登录界面
  Widget _buildAdminLogin() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '管理员后台',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '需要验证管理员身份',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: '管理员密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                    ),
                    onSubmitted: (_) async {
                      await _handleAdminLogin(passwordController.text);
                      passwordController.clear();
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: AdminService().isLoading
                        ? null
                        : () async {
                            await _handleAdminLogin(passwordController.text);
                            passwordController.clear();
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 16),
                    ),
                    child: AdminService().isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('登录'),
                  ),
                  if (AdminService().errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      AdminService().errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 处理管理员登录
  Future<void> _handleAdminLogin(String password) async {
    if (password.isEmpty) {
      return;
    }

    final result = await AdminService().login(password);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        
        // 登录成功后延迟加载数据，避免token时序问题
        Future.delayed(const Duration(milliseconds: 500), () async {
          if (AdminService().isAuthenticated) {
            try {
              await AdminService().fetchUsers();
              await AdminService().fetchStats();
            } catch (e) {
              print('❌ [DeveloperPage] 数据加载失败: $e');
              // 不自动登出，让用户手动重试
            }
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 构建管理员面板
  Widget _buildAdminPanel() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: '用户列表', icon: Icon(Icons.people)),
                    Tab(text: '赞助排行', icon: Icon(Icons.leaderboard)),
                    Tab(text: '统计数据', icon: Icon(Icons.bar_chart)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: '刷新数据',
                        onPressed: AdminService().isLoading
                            ? null
                            : () async {
                                try {
                                  await AdminService().fetchUsers();
                                  await AdminService().fetchStats();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('刷新失败: ${e.toString()}'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('退出管理员'),
                              content: const Text('确定要退出管理员后台吗？'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('取消'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    AdminService().logout();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('确定'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('退出'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildUsersTab(),
                _buildSponsorRankingTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户列表标签页
  Widget _buildUsersTab() {
    if (AdminService().isLoading && AdminService().users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 检查是否有错误信息
    if (AdminService().errorMessage != null && 
        AdminService().errorMessage!.contains('令牌验证失败')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '数据加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AdminService().errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await AdminService().fetchUsers();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                AdminService().logout();
              },
              child: const Text('重新登录'),
            ),
          ],
        ),
      );
    }

    if (AdminService().users.isEmpty) {
      return const Center(child: Text('暂无用户数据'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: AdminService().users.length,
      itemBuilder: (context, index) {
        final user = AdminService().users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Text(user.username[0].toUpperCase())
                  : null,
            ),
            title: Text(user.username),
            subtitle: Text(user.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (user.isVerified)
                  const Icon(Icons.verified, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.favorite, color: Colors.pink),
                  tooltip: '赞助管理',
                  onPressed: () => _showSponsorDialog(user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: '删除用户',
                  onPressed: () => _confirmDeleteUser(user),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoRow('用户ID', user.id.toString()),
                    _buildUserInfoRow('注册时间', _formatDateTime(user.createdAt)),
                    _buildUserInfoRow('最后登录', _formatDateTime(user.lastLogin)),
                    _buildUserInfoRow('IP地址', user.lastIp ?? '未知'),
                    _buildUserInfoRow('IP归属地', user.lastIpLocation ?? '未知'),
                    _buildUserInfoRow('IP更新时间', _formatDateTime(user.lastIpUpdatedAt)),
                    _buildUserInfoRow('验证状态', user.isVerified ? '已验证' : '未验证'),
                    if (user.verifiedAt != null)
                      _buildUserInfoRow('验证时间', _formatDateTime(user.verifiedAt)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建赞助排行榜标签页
  Widget _buildSponsorRankingTab() {
    return FutureBuilder<SponsorRankingData?>(
      future: AdminService().fetchSponsorRanking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('加载赞助排行榜失败'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 汇总卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.leaderboard, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '赞助汇总',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('总赞助金额', '¥${data.summary.totalDonations.toStringAsFixed(2)}', Icons.attach_money),
                        _buildStatCard('赞助用户', data.summary.totalSponsors.toString(), Icons.verified),
                        _buildStatCard('参与人数', data.summary.totalUsers.toString(), Icons.people),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 排行榜列表
            Text(
              '赞助排行榜',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (data.ranking.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('暂无赞助记录', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...data.ranking.map((item) => _buildRankingItem(item)),
          ],
        );
      },
    );
  }

  /// 构建排行榜项
  Widget _buildRankingItem(SponsorRankingItem item) {
    // 前三名使用金银铜色
    Color? rankColor;
    IconData rankIcon = Icons.emoji_events;
    if (item.rank == 1) {
      rankColor = const Color(0xFFFFD700); // 金
    } else if (item.rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // 银
    } else if (item.rank == 3) {
      rankColor = const Color(0xFFCD7F32); // 铜
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 排名
            SizedBox(
              width: 40,
              child: item.rank <= 3
                  ? Icon(rankIcon, color: rankColor, size: 28)
                  : Text(
                      '#${item.rank}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
            const SizedBox(width: 8),
            // 头像
            CircleAvatar(
              radius: 20,
              backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
              child: item.avatarUrl == null ? Text(item.username[0].toUpperCase()) : null,
            ),
          ],
        ),
        title: Row(
          children: [
            Text(item.username, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (item.isSponsor) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.amber, size: 16),
            ],
          ],
        ),
        subtitle: Text('赞助 ${item.donationCount} 次 · ${_formatDateTime(item.lastDonationAt)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '¥${item.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        onTap: () => _showSponsorDialogFromRanking(item),
      ),
    );
  }

  /// 从排行榜项打开赞助详情
  void _showSponsorDialogFromRanking(SponsorRankingItem item) async {
    final details = await AdminService().fetchUserSponsorDetails(item.userId);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.pink),
            const SizedBox(width: 8),
            Expanded(child: Text('赞助详情 - ${item.username}')),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户信息
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
                      child: item.avatarUrl == null ? Text(item.username[0].toUpperCase()) : null,
                    ),
                    title: Row(
                      children: [
                        Text(item.username),
                        if (item.isSponsor) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.amber, size: 16),
                        ],
                      ],
                    ),
                    subtitle: Text(item.email),
                  ),
                ),
                const SizedBox(height: 16),

                // 赞助统计
                _buildUserInfoRow('排名', '#${item.rank}'),
                _buildUserInfoRow('累计赞助', '¥${item.totalAmount.toStringAsFixed(2)}'),
                _buildUserInfoRow('赞助次数', '${item.donationCount} 次'),
                if (item.sponsorSince != null)
                  _buildUserInfoRow('赞助时间', _formatDateTime(item.sponsorSince)),
                const SizedBox(height: 16),

                // 赞助记录
                Text(
                  '赞助记录 (${details?.donations.length ?? 0})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (details?.donations.isEmpty ?? true)
                  const Text('暂无赞助记录', style: TextStyle(color: Colors.grey))
                else
                  ...details!.donations.map((donation) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            donation.isPaid ? Icons.check_circle : Icons.pending,
                            color: donation.isPaid ? Colors.green : Colors.orange,
                          ),
                          title: Text('¥${donation.amount.toStringAsFixed(2)}'),
                          subtitle: Text(
                            '${donation.paymentTypeText} · ${donation.statusText}\n${_formatDateTime(donation.paidAt ?? donation.createdAt)}',
                          ),
                          isThreeLine: true,
                        ),
                      )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建统计数据标签页
  Widget _buildStatsTab() {
    if (AdminService().isLoading && AdminService().stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 检查是否有错误信息
    if (AdminService().errorMessage != null && 
        AdminService().errorMessage!.contains('令牌验证失败')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '统计数据加载失败',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AdminService().errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                await AdminService().fetchStats();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                AdminService().logout();
              },
              child: const Text('重新登录'),
            ),
          ],
        ),
      );
    }

    final stats = AdminService().stats;
    if (stats == null) {
      return const Center(child: Text('暂无统计数据'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 概览卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dashboard, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '用户概览',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('总用户', stats.totalUsers.toString(), Icons.people),
                    _buildStatCard('已验证', stats.verifiedUsers.toString(), Icons.verified),
                    _buildStatCard('未验证', stats.unverifiedUsers.toString(), Icons.pending),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('今日新增', stats.todayUsers.toString(), Icons.person_add),
                    _buildStatCard('今日活跃', stats.todayActiveUsers.toString(), Icons.trending_up),
                    _buildStatCard('本周新增', stats.last7DaysUsers.toString(), Icons.calendar_today),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 地区分布
        if (stats.topLocations.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '地区分布 Top 10',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(),
                  ...stats.topLocations.map((loc) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(loc.location),
                            ),
                            Expanded(
                              flex: 7,
                              child: Stack(
                                children: [
                                  Container(
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    width: (loc.count / stats.totalUsers) *
                                        MediaQuery.of(context).size.width *
                                        0.6,
                                  ),
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          '${loc.count} 人',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 注册趋势
        if (stats.registrationTrend.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '30天注册趋势',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    '最近30天共 ${stats.last30DaysUsers} 人注册',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// 构建用户信息行
  Widget _buildUserInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value ?? '未知',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '未知';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  /// 确认删除用户
  void _confirmDeleteUser(user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除用户'),
        content: Text('确定要删除用户 "${user.username}" 吗？\n\n此操作无法撤销！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await AdminService().deleteUser(user.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '用户已删除' : '删除失败'),
                    backgroundColor: success
                        ? Colors.green
                        : Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示赞助管理对话框
  void _showSponsorDialog(AdminUserData user) async {
    // 先获取用户赞助详情
    final details = await AdminService().fetchUserSponsorDetails(user.id);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.pink),
                const SizedBox(width: 8),
                Text('赞助管理 - ${user.username}'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 赞助状态
                    Card(
                      child: ListTile(
                        leading: Icon(
                          details?.isSponsor == true ? Icons.verified : Icons.cancel,
                          color: details?.isSponsor == true ? Colors.amber : Colors.grey,
                        ),
                        title: Text(details?.isSponsor == true ? '赞助用户' : '非赞助用户'),
                        subtitle: details?.sponsorSince != null
                            ? Text('赞助时间: ${_formatDateTime(details!.sponsorSince)}')
                            : null,
                        trailing: Switch.adaptive(
                          value: details?.isSponsor ?? false,
                          onChanged: (value) async {
                            final success = await AdminService().updateSponsorStatus(user.id, value);
                            if (success && mounted) {
                              // 刷新详情
                              final newDetails = await AdminService().fetchUserSponsorDetails(user.id);
                              setDialogState(() {
                                // 用新数据
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(value ? '已设为赞助用户' : '已取消赞助状态'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                              _showSponsorDialog(user); // 重新打开对话框以刷新数据
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 累计赞助金额
                    _buildUserInfoRow('累计赞助金额', '¥${details?.totalAmount.toStringAsFixed(2) ?? "0.00"}'),
                    const SizedBox(height: 16),

                    // 赞助记录列表
                    Text(
                      '赞助记录 (${details?.donations.length ?? 0})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    if (details?.donations.isEmpty ?? true)
                      const Text('暂无赞助记录', style: TextStyle(color: Colors.grey))
                    else
                      ...details!.donations.map((donation) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(
                                donation.isPaid ? Icons.check_circle : Icons.pending,
                                color: donation.isPaid ? Colors.green : Colors.orange,
                              ),
                              title: Text('¥${donation.amount.toStringAsFixed(2)}'),
                              subtitle: Text(
                                '${donation.paymentTypeText} · ${donation.statusText}\n${_formatDateTime(donation.paidAt ?? donation.createdAt)}',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: '删除记录',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('删除赞助记录'),
                                      content: Text('确定要删除这笔 ¥${donation.amount.toStringAsFixed(2)} 的赞助记录吗？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('取消'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Theme.of(context).colorScheme.error,
                                          ),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    final success = await AdminService().deleteDonation(donation.id);
                                    if (success && mounted) {
                                      Navigator.pop(context);
                                      _showSponsorDialog(user); // 重新打开对话框
                                    }
                                  }
                                },
                              ),
                            ),
                          )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              FilledButton.icon(
                onPressed: () => _showAddDonationDialog(user),
                icon: const Icon(Icons.add),
                label: const Text('添加赞助'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 显示添加赞助对话框
  void _showAddDonationDialog(AdminUserData user) {
    final amountController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('为 ${user.username} 添加赞助'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '赞助金额 (元)',
                    prefixText: '¥ ',
                    errorText: errorText,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '添加后将自动标记为已支付，并将用户设为赞助用户',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  final amountStr = amountController.text.trim();
                  final amount = double.tryParse(amountStr);
                  if (amount == null || amount <= 0) {
                    setDialogState(() => errorText = '请输入有效金额');
                    return;
                  }

                  final success = await AdminService().addManualDonation(user.id, amount);
                  if (mounted) {
                    Navigator.pop(context); // 关闭添加对话框
                    Navigator.pop(context); // 关闭赞助管理对话框
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? '赞助记录已添加' : '添加失败'),
                        backgroundColor: success ? Colors.green : Theme.of(context).colorScheme.error,
                      ),
                    );
                    if (success) {
                      _showSponsorDialog(user); // 重新打开赞助管理对话框
                    }
                  }
                },
                child: const Text('确认添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建设置标签页
  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本信息'),
            subtitle: const Text('Cyrene Music v1.0.0'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.flutter_dash),
            title: const Text('Flutter 版本'),
            subtitle: const Text('3.32.7'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.smartphone),
            title: const Text('平台'),
            subtitle: Text(_getPlatformName()),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.merge_type),
            title: const Text('合并搜索结果'),
            subtitle: const Text('关闭后将分平台显示搜索结果（网易云/QQ/酷狗/酷我）'),
            trailing: Switch.adaptive(
              value: DeveloperModeService().isSearchResultMergeEnabled,
              onChanged: (value) {
                setState(() {
                  DeveloperModeService().toggleSearchResultMerge(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.show_chart),
            title: const Text('性能叠加层'),
            subtitle: const Text('开启后在界面顶部显示帧率和渲染监控曲线'),
            trailing: Switch.adaptive(
              value: DeveloperModeService().showPerformanceOverlay,
              onChanged: (value) {
                setState(() {
                  DeveloperModeService().togglePerformanceOverlay(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.api),
            title: const Text('API 日志'),
            subtitle: const Text('记录所有 API 请求和响应到日志'),
            trailing: Switch.adaptive(
              value: DeveloperModeService().enableApiLogging,
              onChanged: (value) {
                setState(() {
                  DeveloperModeService().toggleApiLogging(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('详细日志'),
            subtitle: const Text('记录详细的调试信息（会产生大量日志）'),
            trailing: Switch.adaptive(
              value: DeveloperModeService().enableVerboseLogging,
              onChanged: (value) {
                setState(() {
                  DeveloperModeService().toggleVerboseLogging(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            await NotificationService().showNotification(
              id: 999,
              title: '测试通知',
              body: '这是一条来自开发者模式的测试通知',
            );
          },
          icon: const Icon(Icons.notifications),
          label: const Text('发送测试通知'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            await _testPlaybackResumeNotification();
          },
          icon: const Icon(Icons.play_circle_outline),
          label: const Text('测试播放恢复通知'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            await _clearPlaybackSession();
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('清除播放状态'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          '音源测试',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LxMusicRuntimeTestPage(),
              ),
            );
          },
          icon: const Icon(Icons.science),
          label: const Text('洛雪音源运行时测试'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'WSA 专用',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _showQuickLoginDialog(),
          icon: const Icon(Icons.login),
          label: const Text('快速登录'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  /// 显示快速登录对话框（用于 WSA 等无法正常使用登录界面的情况）
  void _showQuickLoginDialog() {
    final accountController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('快速登录'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('直接输入账号密码登录（用于 WSA 等环境）'),
                const SizedBox(height: 16),
                TextField(
                  controller: accountController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: '邮箱 / 用户名',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                  onSubmitted: isLoading ? null : (_) async {
                    setState(() => isLoading = true);
                    await _performQuickLogin(accountController.text, passwordController.text, context);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        await _performQuickLogin(accountController.text, passwordController.text, context);
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('登录'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 执行快速登录
  Future<void> _performQuickLogin(String account, String password, BuildContext dialogContext) async {
    if (account.trim().isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入账号和密码')),
      );
      return;
    }

    final loginResult = await AuthService().login(
      account: account.trim(),
      password: password,
    );

    if (mounted) {
      Navigator.pop(dialogContext);
      
      if (loginResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 登录成功'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 登录成功后上报IP归属地
        AuthService().updateLocation().then((locationResult) {
          if (locationResult['success']) {
            DeveloperModeService().addLog('✅ IP归属地已更新: ${locationResult['data']?['location']}');
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登录失败: ${loginResult['message']}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 测试播放恢复通知
  Future<void> _testPlaybackResumeNotification() async {
    try {
      // 获取上次播放状态（如果有的话）
      final state = await PlaybackStateService().getLastPlaybackState();
      
      String trackName;
      String artist;
      String? coverUrl;
      String? platformInfo;
      
      if (state != null) {
        // 使用实际保存的播放状态
        trackName = state.track.name;
        artist = state.track.artists;
        coverUrl = state.coverUrl;
        platformInfo = state.isCrossPlatform ? state.platformDisplayText : null;
        DeveloperModeService().addLog('📱 使用真实播放状态: $trackName - $artist');
        DeveloperModeService().addLog('🖼️ 封面URL: $coverUrl');
        if (platformInfo != null) {
          DeveloperModeService().addLog('🌐 平台信息: $platformInfo');
        }
      } else {
        // 如果没有保存的状态，使用测试数据
        trackName = '测试歌曲';
        artist = '测试歌手';
        coverUrl = 'https://p2.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg';
        platformInfo = null; // 测试时不显示平台信息
        DeveloperModeService().addLog('📱 使用测试数据（没有保存的播放状态）');
      }
      
      // 显示恢复播放通知
      await NotificationService().showResumePlaybackNotification(
        trackName: trackName,
        artist: artist,
        coverUrl: coverUrl,
        platformInfo: platformInfo,
        payload: 'test_resume_playback',
      );
      
      DeveloperModeService().addLog('✅ 播放恢复通知已发送');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('播放恢复通知已发送')),
        );
      }
    } catch (e) {
      DeveloperModeService().addLog('❌ 发送播放恢复通知失败: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
      }
    }
  }

  /// 清除播放会话
  Future<void> _clearPlaybackSession() async {
    // 检查是否是 Fluent UI
    final isFluent = Platform.isWindows && ThemeManager().isFluentFramework;

    if (isFluent) {
      showDialog(
        context: context,
        builder: (context) => fluent.ContentDialog(
          title: const Text('清除本地播放状态'),
          content: const Text('确定要清除当前的播放会话吗？\n\n这将停止播放并重置播放器，但不会删除云端保存的播放进度。'),
          actions: [
            fluent.Button(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            fluent.FilledButton(
              style: fluent.ButtonStyle(
                backgroundColor: fluent.ButtonState.all(fluent.Colors.red),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _performClearSession();
              },
              child: const Text('清除'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('清除本地播放状态'),
          content: const Text('确定要清除当前的播放会话吗？\n\n这将停止播放并重置播放器，但不会删除云端保存的播放进度。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performClearSession();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('清除'),
            ),
          ],
        ),
      );
    }
  }

  /// 执行清除操作
  Future<void> _performClearSession() async {
    // 1. 清除播放器会话
    await PlayerService().clearSession();
    
    // 2. 取消所有通知
    await NotificationService().cancelAll();
    
    if (mounted) {
      final isFluent = Platform.isWindows && ThemeManager().isFluentFramework;
      if (isFluent) {
        _showFluentSnackbar('✅ 本地播放状态已清除');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 本地播放状态已清除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// 构建数据区块
  Widget _buildDataSection(String title, IconData icon, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SelectableText(
                item,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFluentPage(BuildContext context) {
    return fluent.ScaffoldPage(
      header: fluent.PageHeader(
        title: const Text('开发者模式'),
        commandBar: fluent.CommandBar(
          primaryItems: [
            fluent.CommandBarButton(
              icon: const Icon(fluent.FluentIcons.power_button),
              label: const Text('退出开发者模式'),
              onPressed: () {
                _showFluentExitDialog();
              },
            ),
          ],
        ),
      ),
      content: fluent.TabView(
        currentIndex: _fluentTabIndex,
        onChanged: (index) => setState(() => _fluentTabIndex = index),
        tabs: [
          fluent.Tab(
            text: const Text('日志'),
            icon: const Icon(fluent.FluentIcons.error),
            body: _buildFluentLogTab(),
          ),
          fluent.Tab(
            text: const Text('数据'),
            icon: const Icon(fluent.FluentIcons.database),
            body: _buildFluentDataTab(),
          ),
          fluent.Tab(
            text: const Text('设置'),
            icon: const Icon(fluent.FluentIcons.settings),
            body: _buildFluentSettingsTab(),
          ),
        ],
      ),
    );
  }

  void _showFluentExitDialog() {
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('退出开发者模式'),
        content: const Text('确定要退出开发者模式吗？'),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          fluent.FilledButton(
            onPressed: () {
              DeveloperModeService().disableDeveloperMode();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildFluentLogTab() {
    return AnimatedBuilder(
      animation: DeveloperModeService(),
      builder: (context, child) {
        final logs = DeveloperModeService().logs;
        
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: fluent.CommandBar(
                primaryItems: [
                  fluent.CommandBarButton(
                    icon: const Icon(fluent.FluentIcons.copy),
                    label: const Text('复制全部'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: logs.join('\n')));
                      _showFluentSnackbar('已复制到剪贴板');
                    },
                  ),
                  fluent.CommandBarButton(
                    icon: const Icon(fluent.FluentIcons.delete),
                    label: const Text('清除日志'),
                    onPressed: () {
                      DeveloperModeService().clearLogs();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('暂无日志'))
                  : ListView.builder(
                      controller: _logScrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: SelectableText(
                            log,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showFluentSnackbar(String message) {
    fluent.displayInfoBar(
      context,
      builder: (context, close) {
        return fluent.InfoBar(
          title: Text(message),
          onClose: close,
        );
      },
    );
  }

  Widget _buildFluentDataTab() {
    return AnimatedBuilder(
      animation: AdminService(),
      builder: (context, child) {
        if (!AdminService().isAuthenticated) {
          return _buildFluentAdminLogin();
        } else {
          return _buildFluentAdminPanel();
        }
      },
    );
  }

  Widget _buildFluentAdminLogin() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: StatefulBuilder(
            builder: (context, setState) {
              return fluent.Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      fluent.FluentIcons.shield,
                      size: 60,
                      color: fluent.FluentTheme.of(context).accentColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '管理员后台',
                      style: fluent.FluentTheme.of(context).typography.title,
                    ),
                    const SizedBox(height: 8),
                    const Text('需要验证管理员身份'),
                    const SizedBox(height: 32),
                    fluent.TextBox(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      placeholder: '管理员密码',
                      suffix: fluent.IconButton(
                        icon: Icon(
                          obscurePassword
                              ? fluent.FluentIcons.view
                              : fluent.FluentIcons.hide,
                        ),
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                      onSubmitted: (_) async {
                        await _handleAdminLogin(passwordController.text);
                        passwordController.clear();
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: fluent.FilledButton(
                        onPressed: AdminService().isLoading
                            ? null
                            : () async {
                                await _handleAdminLogin(passwordController.text);
                                passwordController.clear();
                              },
                        child: AdminService().isLoading
                            ? const fluent.ProgressRing(strokeWidth: 2.5)
                            : const Text('登录'),
                      ),
                    ),
                    if (AdminService().errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        AdminService().errorMessage!,
                        style: TextStyle(
                          color: fluent.Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFluentAdminPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: fluent.CommandBar(
            primaryItems: [
              fluent.CommandBarButton(
                icon: const Icon(fluent.FluentIcons.refresh),
                label: const Text('刷新'),
                onPressed: AdminService().isLoading ? null : () async {
                  try {
                    await AdminService().fetchUsers();
                    await AdminService().fetchStats();
                  } catch (e) {
                    if (mounted) _showFluentSnackbar('刷新失败: $e');
                  }
                },
              ),
              fluent.CommandBarButton(
                icon: const Icon(fluent.FluentIcons.sign_out),
                label: const Text('退出'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => fluent.ContentDialog(
                      title: const Text('退出管理员'),
                      content: const Text('确定要退出管理员后台吗？'),
                      actions: [
                        fluent.Button(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('取消'),
                        ),
                        fluent.FilledButton(
                          onPressed: () {
                            AdminService().logout();
                            Navigator.pop(context);
                          },
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: fluent.TabView(
            currentIndex: _fluentAdminTabIndex,
            onChanged: (index) => setState(() => _fluentAdminTabIndex = index),
            tabs: [
              fluent.Tab(
                text: const Text('用户列表'),
                icon: const Icon(fluent.FluentIcons.people),
                body: _buildFluentUsersTab(),
              ),
              fluent.Tab(
                text: const Text('赞助排行'),
                icon: const Icon(fluent.FluentIcons.trophy2),
                body: _buildFluentSponsorRankingTab(),
              ),
              fluent.Tab(
                text: const Text('统计数据'),
                icon: const Icon(fluent.FluentIcons.chart),
                body: _buildFluentStatsTab(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFluentUsersTab() {
    if (AdminService().isLoading && AdminService().users.isEmpty) {
      return const Center(child: fluent.ProgressRing());
    }

    if (AdminService().errorMessage != null && 
        AdminService().errorMessage!.contains('令牌验证失败')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(fluent.FluentIcons.error, size: 48, color: fluent.Colors.red),
            const SizedBox(height: 16),
            const Text('数据加载失败'),
            const SizedBox(height: 8),
            Text(AdminService().errorMessage!),
            const SizedBox(height: 24),
            fluent.Button(
              onPressed: () {
                AdminService().logout();
              },
              child: const Text('重新登录'),
            ),
          ],
        ),
      );
    }

    if (AdminService().users.isEmpty) {
      return const Center(child: Text('暂无用户数据'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: AdminService().users.length,
      itemBuilder: (context, index) {
        final user = AdminService().users[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: fluent.Expander(
            header: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(user.username[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(user.email, style: fluent.FluentTheme.of(context).typography.caption),
                  ],
                ),
                const Spacer(),
                if (user.isVerified)
                  Icon(fluent.FluentIcons.verified_brand, color: fluent.Colors.green, size: 16),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoRow('用户ID', user.id.toString()),
                _buildUserInfoRow('注册时间', _formatDateTime(user.createdAt)),
                _buildUserInfoRow('最后登录', _formatDateTime(user.lastLogin)),
                _buildUserInfoRow('IP地址', user.lastIp ?? '未知'),
                _buildUserInfoRow('IP归属地', user.lastIpLocation ?? '未知'),
                _buildUserInfoRow('IP更新时间', _formatDateTime(user.lastIpUpdatedAt)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    fluent.Button(
                      onPressed: () => _showFluentSponsorDialog(user),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(fluent.FluentIcons.heart, size: 16, color: Colors.pink),
                          SizedBox(width: 8),
                          Text('赞助管理'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    fluent.Button(
                      style: fluent.ButtonStyle(
                        foregroundColor: fluent.ButtonState.all(fluent.Colors.red),
                      ),
                      onPressed: () => _confirmFluentDeleteUser(user),
                      child: const Text('删除用户'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmFluentDeleteUser(user) {
    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: const Text('删除用户'),
        content: Text('确定要删除用户 "${user.username}" 吗？\n\n此操作无法撤销！'),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          fluent.FilledButton(
            style: fluent.ButtonStyle(
              backgroundColor: fluent.ButtonState.all(fluent.Colors.red),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await AdminService().deleteUser(user.id);
              if (mounted) {
                _showFluentSnackbar(success ? '用户已删除' : '删除失败');
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示 Fluent UI 赞助管理对话框
  void _showFluentSponsorDialog(AdminUserData user) async {
    final details = await AdminService().fetchUserSponsorDetails(user.id);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Row(
          children: [
            const Icon(fluent.FluentIcons.heart, color: Colors.pink),
            const SizedBox(width: 8),
            Text('赞助管理 - ${user.username}'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 赞助状态卡片
                fluent.Card(
                  child: Row(
                    children: [
                      Icon(
                        details?.isSponsor == true ? fluent.FluentIcons.verified_brand : fluent.FluentIcons.cancel,
                        color: details?.isSponsor == true ? fluent.Colors.orange : fluent.Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              details?.isSponsor == true ? '赞助用户' : '非赞助用户',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (details?.sponsorSince != null)
                              Text(
                                '赞助时间: ${_formatDateTime(details!.sponsorSince)}',
                                style: fluent.FluentTheme.of(context).typography.caption,
                              ),
                          ],
                        ),
                      ),
                      fluent.ToggleSwitch(
                        checked: details?.isSponsor ?? false,
                        onChanged: (value) async {
                          final success = await AdminService().updateSponsorStatus(user.id, value);
                          if (success && mounted) {
                            Navigator.pop(context);
                            _showFluentSnackbar(value ? '已设为赞助用户' : '已取消赞助状态');
                            _showFluentSponsorDialog(user);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 累计金额
                _buildUserInfoRow('累计赞助金额', '¥${details?.totalAmount.toStringAsFixed(2) ?? "0.00"}'),
                const SizedBox(height: 16),

                // 赞助记录
                Text(
                  '赞助记录 (${details?.donations.length ?? 0})',
                  style: fluent.FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 8),
                if (details?.donations.isEmpty ?? true)
                  Text('暂无赞助记录', style: fluent.FluentTheme.of(context).typography.caption)
                else
                  ...details!.donations.map((donation) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: fluent.Card(
                          child: Row(
                            children: [
                              Icon(
                                donation.isPaid ? fluent.FluentIcons.check_mark : fluent.FluentIcons.clock,
                                color: donation.isPaid ? fluent.Colors.green : fluent.Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¥${donation.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${donation.paymentTypeText} · ${donation.statusText}',
                                      style: fluent.FluentTheme.of(context).typography.caption,
                                    ),
                                    Text(
                                      _formatDateTime(donation.paidAt ?? donation.createdAt),
                                      style: fluent.FluentTheme.of(context).typography.caption,
                                    ),
                                  ],
                                ),
                              ),
                              fluent.IconButton(
                                icon: Icon(fluent.FluentIcons.delete, color: fluent.Colors.red, size: 16),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => fluent.ContentDialog(
                                      title: const Text('删除赞助记录'),
                                      content: Text('确定要删除这笔 ¥${donation.amount.toStringAsFixed(2)} 的赞助记录吗？'),
                                      actions: [
                                        fluent.Button(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('取消'),
                                        ),
                                        fluent.FilledButton(
                                          style: fluent.ButtonStyle(
                                            backgroundColor: fluent.ButtonState.all(fluent.Colors.red),
                                          ),
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('删除'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    final success = await AdminService().deleteDonation(donation.id);
                                    if (success && mounted) {
                                      Navigator.pop(context);
                                      _showFluentSponsorDialog(user);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          fluent.FilledButton(
            onPressed: () => _showFluentAddDonationDialog(user),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(fluent.FluentIcons.add, size: 16),
                SizedBox(width: 8),
                Text('添加赞助'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 显示 Fluent UI 添加赞助对话框
  void _showFluentAddDonationDialog(AdminUserData user) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          String? errorText;
          return fluent.ContentDialog(
            title: Text('为 ${user.username} 添加赞助'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fluent.TextBox(
                  controller: amountController,
                  placeholder: '赞助金额 (元)',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text('¥'),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(errorText!, style: TextStyle(color: fluent.Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                Text(
                  '添加后将自动标记为已支付，并将用户设为赞助用户',
                  style: fluent.FluentTheme.of(context).typography.caption,
                ),
              ],
            ),
            actions: [
              fluent.Button(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              fluent.FilledButton(
                onPressed: () async {
                  final amountStr = amountController.text.trim();
                  final amount = double.tryParse(amountStr);
                  if (amount == null || amount <= 0) {
                    setDialogState(() => errorText = '请输入有效金额');
                    return;
                  }

                  final success = await AdminService().addManualDonation(user.id, amount);
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _showFluentSnackbar(success ? '赞助记录已添加' : '添加失败');
                    if (success) {
                      _showFluentSponsorDialog(user);
                    }
                  }
                },
                child: const Text('确认添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建 Fluent UI 赞助排行榜标签页
  Widget _buildFluentSponsorRankingTab() {
    return FutureBuilder<SponsorRankingData?>(
      future: AdminService().fetchSponsorRanking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: fluent.ProgressRing());
        }

        final data = snapshot.data;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(fluent.FluentIcons.error, size: 48, color: fluent.Colors.grey),
                const SizedBox(height: 16),
                const Text('加载赞助排行榜失败'),
                const SizedBox(height: 16),
                fluent.FilledButton(
                  onPressed: () => setState(() {}),
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 汇总卡片
            fluent.Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(fluent.FluentIcons.trophy2, color: fluent.Colors.orange),
                      const SizedBox(width: 8),
                      Text('赞助汇总', style: fluent.FluentTheme.of(context).typography.subtitle),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFluentStatCard('总赞助金额', '¥${data.summary.totalDonations.toStringAsFixed(2)}', fluent.FluentIcons.money),
                      _buildFluentStatCard('赞助用户', data.summary.totalSponsors.toString(), fluent.FluentIcons.verified_brand),
                      _buildFluentStatCard('参与人数', data.summary.totalUsers.toString(), fluent.FluentIcons.people),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 排行榜标题
            Text('赞助排行榜', style: fluent.FluentTheme.of(context).typography.bodyStrong),
            const SizedBox(height: 8),

            if (data.ranking.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('暂无赞助记录', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...data.ranking.map((item) => _buildFluentRankingItem(item)),
          ],
        );
      },
    );
  }

  /// 构建 Fluent UI 排行榜项
  Widget _buildFluentRankingItem(SponsorRankingItem item) {
    Color? rankColor;
    if (item.rank == 1) {
      rankColor = const Color(0xFFFFD700);
    } else if (item.rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
    } else if (item.rank == 3) {
      rankColor = const Color(0xFFCD7F32);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: fluent.Card(
        child: fluent.ListTile.selectable(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                child: item.rank <= 3
                    ? Icon(fluent.FluentIcons.trophy2, color: rankColor, size: 24)
                    : Text(
                        '#${item.rank}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
                child: item.avatarUrl == null ? Text(item.username[0].toUpperCase()) : null,
              ),
            ],
          ),
          title: Row(
            children: [
              Text(item.username, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (item.isSponsor) ...[
                const SizedBox(width: 4),
                Icon(fluent.FluentIcons.verified_brand, color: fluent.Colors.orange, size: 14),
              ],
            ],
          ),
          subtitle: Text(
            '赞助 ${item.donationCount} 次 · ${_formatDateTime(item.lastDonationAt)}',
            style: fluent.FluentTheme.of(context).typography.caption,
          ),
          trailing: Text(
            '¥${item.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: fluent.Colors.orange,
            ),
          ),
          onPressed: () => _showFluentSponsorDialogFromRanking(item),
        ),
      ),
    );
  }

  /// Fluent UI 从排行榜打开赞助详情
  void _showFluentSponsorDialogFromRanking(SponsorRankingItem item) async {
    final details = await AdminService().fetchUserSponsorDetails(item.userId);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => fluent.ContentDialog(
        title: Row(
          children: [
            const Icon(fluent.FluentIcons.heart, color: Colors.pink),
            const SizedBox(width: 8),
            Expanded(child: Text('赞助详情 - ${item.username}')),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 用户信息卡片
                fluent.Card(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: item.avatarUrl != null ? NetworkImage(item.avatarUrl!) : null,
                        child: item.avatarUrl == null ? Text(item.username[0].toUpperCase()) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(item.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (item.isSponsor) ...[
                                  const SizedBox(width: 4),
                                  Icon(fluent.FluentIcons.verified_brand, color: fluent.Colors.orange, size: 14),
                                ],
                              ],
                            ),
                            Text(item.email, style: fluent.FluentTheme.of(context).typography.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 赞助统计
                _buildUserInfoRow('排名', '#${item.rank}'),
                _buildUserInfoRow('累计赞助', '¥${item.totalAmount.toStringAsFixed(2)}'),
                _buildUserInfoRow('赞助次数', '${item.donationCount} 次'),
                if (item.sponsorSince != null)
                  _buildUserInfoRow('赞助时间', _formatDateTime(item.sponsorSince)),
                const SizedBox(height: 16),

                // 赞助记录
                Text('赞助记录 (${details?.donations.length ?? 0})', style: fluent.FluentTheme.of(context).typography.bodyStrong),
                const SizedBox(height: 8),
                if (details?.donations.isEmpty ?? true)
                  Text('暂无赞助记录', style: fluent.FluentTheme.of(context).typography.caption)
                else
                  ...details!.donations.map((donation) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: fluent.Card(
                          child: Row(
                            children: [
                              Icon(
                                donation.isPaid ? fluent.FluentIcons.check_mark : fluent.FluentIcons.clock,
                                color: donation.isPaid ? fluent.Colors.green : fluent.Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('¥${donation.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(
                                      '${donation.paymentTypeText} · ${donation.statusText}',
                                      style: fluent.FluentTheme.of(context).typography.caption,
                                    ),
                                    Text(
                                      _formatDateTime(donation.paidAt ?? donation.createdAt),
                                      style: fluent.FluentTheme.of(context).typography.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildFluentStatsTab() {
    if (AdminService().isLoading && AdminService().stats == null) {
      return const Center(child: fluent.ProgressRing());
    }
    
    final stats = AdminService().stats;
    if (stats == null) {
      return const Center(child: Text('暂无统计数据'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        fluent.Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('用户概览', style: fluent.FluentTheme.of(context).typography.subtitle),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFluentStatCard('总用户', stats.totalUsers.toString(), fluent.FluentIcons.people),
                  _buildFluentStatCard('已验证', stats.verifiedUsers.toString(), fluent.FluentIcons.verified_brand),
                  _buildFluentStatCard('未验证', stats.unverifiedUsers.toString(), fluent.FluentIcons.unknown),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFluentStatCard('今日新增', stats.todayUsers.toString(), fluent.FluentIcons.add_friend),
                  _buildFluentStatCard('今日活跃', stats.todayActiveUsers.toString(), fluent.FluentIcons.trending12),
                  _buildFluentStatCard('本周新增', stats.last7DaysUsers.toString(), fluent.FluentIcons.calendar),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (stats.topLocations.isNotEmpty) ...[
          fluent.Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('地区分布 Top 10', style: fluent.FluentTheme.of(context).typography.subtitle),
                const SizedBox(height: 16),
                ...stats.topLocations.map((loc) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(loc.location)),
                      Expanded(
                        flex: 7,
                        child: fluent.ProgressBar(
                          value: (loc.count / stats.totalUsers) * 100,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${loc.count} 人'),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFluentStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: fluent.FluentTheme.of(context).accentColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(label, style: fluent.FluentTheme.of(context).typography.caption),
      ],
    );
  }

  Widget _buildFluentSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        fluent.Card(
          child: fluent.ListTile(
            leading: const Icon(fluent.FluentIcons.info),
            title: const Text('版本信息'),
            subtitle: const Text('Cyrene Music v1.0.0'),
          ),
        ),
        const SizedBox(height: 8),
        fluent.Card(
          child: fluent.ListTile(
            leading: const Icon(fluent.FluentIcons.code),
            title: const Text('Flutter 版本'),
            subtitle: const Text('3.32.7'),
          ),
        ),
        const SizedBox(height: 8),
        fluent.Card(
          child: fluent.ListTile(
            leading: const Icon(fluent.FluentIcons.cell_phone),
            title: const Text('平台'),
            subtitle: Text(_getPlatformName()),
          ),
        ),
        const SizedBox(height: 8),
        fluent.Card(
          child: fluent.ListTile(
            leading: const Icon(fluent.FluentIcons.merge),
            title: const Text('合并搜索结果'),
            subtitle: const Text('关闭后将分平台显示搜索结果（网易云/QQ/酷狗/酷我）'),
            trailing: fluent.ToggleSwitch(
              checked: DeveloperModeService().isSearchResultMergeEnabled,
              onChanged: (value) {
                setState(() {
                  DeveloperModeService().toggleSearchResultMerge(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        fluent.Card(
          child: fluent.ListTile(
            leading: const Icon(fluent.FluentIcons.line_chart),
            title: const Text('性能叠加层'),
            subtitle: const Text('开启后在界面顶部显示帧率和渲染监控曲线'),
            trailing: fluent.ToggleSwitch(
              checked: DeveloperModeService().showPerformanceOverlay,
              onChanged: (value) {
                setState(() {
                  DeveloperModeService().togglePerformanceOverlay(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        fluent.FilledButton(
          onPressed: () {
            DeveloperModeService().addLog('📋 触发测试日志');
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fluent.FluentIcons.bug),
              SizedBox(width: 8),
              Text('添加测试日志'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        fluent.FilledButton(
          onPressed: () async {
            await NotificationService().showNotification(
              id: 999,
              title: '测试通知',
              body: '这是一条来自开发者模式的测试通知',
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fluent.FluentIcons.ringer),
              SizedBox(width: 8),
              Text('发送测试通知'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        fluent.FilledButton(
          onPressed: () async {
            await _testPlaybackResumeNotification();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fluent.FluentIcons.play),
              SizedBox(width: 8),
              Text('测试播放恢复通知'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        fluent.FilledButton(
          style: fluent.ButtonStyle(
            backgroundColor: fluent.ButtonState.all(fluent.Colors.red),
          ),
          onPressed: () async {
            await _clearPlaybackSession();
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fluent.FluentIcons.delete),
              SizedBox(width: 8),
              Text('清除播放状态'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          '音源测试',
          style: fluent.FluentTheme.of(context).typography.bodyStrong?.copyWith(
            color: fluent.FluentTheme.of(context).accentColor,
          ),
        ),
        const SizedBox(height: 8),
        fluent.FilledButton(
          style: fluent.ButtonStyle(
            backgroundColor: fluent.WidgetStateProperty.all(fluent.Colors.teal),
          ),
          onPressed: () {
            Navigator.push(
              context,
              fluent.FluentPageRoute(
                builder: (context) => const LxMusicRuntimeTestPage(),
              ),
            );
          },
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fluent.FluentIcons.test_beaker),
              SizedBox(width: 8),
              Text('洛雪音源运行时测试'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'WSA 专用',
          style: fluent.FluentTheme.of(context).typography.bodyStrong?.copyWith(
            color: fluent.FluentTheme.of(context).accentColor,
          ),
        ),
        const SizedBox(height: 8),
        fluent.FilledButton(
          style: fluent.ButtonStyle(
            backgroundColor: fluent.WidgetStateProperty.all(fluent.Colors.purple),
          ),
          onPressed: () => _showFluentQuickLoginDialog(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fluent.FluentIcons.signin),
              SizedBox(width: 8),
              Text('快速登录'),
            ],
          ),
        ),
      ],
    );
  }

  /// 显示 Fluent UI 版本的快速登录对话框
  void _showFluentQuickLoginDialog() {
    final accountController = TextEditingController();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return fluent.ContentDialog(
            title: Row(
              children: [
                Icon(fluent.FluentIcons.signin, color: fluent.FluentTheme.of(context).accentColor),
                const SizedBox(width: 8),
                const Text('快速登录'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('直接输入账号密码登录（用于 WSA 等环境）'),
                const SizedBox(height: 16),
                fluent.TextBox(
                  controller: accountController,
                  enabled: !isLoading,
                  placeholder: '邮箱 / 用户名',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(fluent.FluentIcons.contact, size: 16),
                  ),
                ),
                const SizedBox(height: 12),
                fluent.TextBox(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  enabled: !isLoading,
                  placeholder: '密码',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(fluent.FluentIcons.lock, size: 16),
                  ),
                  suffix: fluent.IconButton(
                    icon: Icon(
                      obscurePassword
                          ? fluent.FluentIcons.view
                          : fluent.FluentIcons.hide3,
                      size: 16,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                  onSubmitted: isLoading ? null : (_) async {
                    setState(() => isLoading = true);
                    await _performQuickLogin(accountController.text, passwordController.text, context);
                  },
                ),
              ],
            ),
            actions: [
              fluent.Button(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              fluent.FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        await _performQuickLogin(accountController.text, passwordController.text, context);
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: fluent.ProgressRing(strokeWidth: 2),
                      )
                    : const Text('登录'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getPlatformName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    if (kIsWeb) return 'Web';
    return 'Unknown';
  }

  // ============ iOS Cupertino 主题 ============

  /// 构建 iOS Cupertino 风格页面
  Widget _buildCupertinoPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 底部 Tab 栏高度（悬浮 Tab 栏约 60 + 底部安全区）
    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;
    
    return Material(
      type: MaterialType.transparency,
      child: CupertinoPageScaffold(
        backgroundColor: isDark ? CupertinoColors.black : CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('开发者模式'),
          backgroundColor: (isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white).withOpacity(0.9),
          border: null,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.power),
            onPressed: () => _showCupertinoExitDialog(context, isDark),
          ),
        ),
        child: SafeArea(
          bottom: false, // 不使用 SafeArea 的底部，手动处理
          child: Column(
            children: [
              // 分段控制器
              Padding(
                padding: const EdgeInsets.all(16),
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _cupertinoTabIndex,
                  onValueChanged: (value) {
                    if (value != null) {
                      setState(() => _cupertinoTabIndex = value);
                    }
                  },
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('日志'),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('数据'),
                    ),
                    2: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('设置'),
                    ),
                  },
                ),
              ),
              // 内容区域（底部留出 Tab 栏空间）
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildCupertinoTabContent(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建 Cupertino 标签页内容
  Widget _buildCupertinoTabContent(bool isDark) {
    switch (_cupertinoTabIndex) {
      case 0:
        return _buildCupertinoLogTab(isDark);
      case 1:
        return _buildCupertinoDataTab(isDark);
      case 2:
        return _buildCupertinoSettingsTab(isDark);
      default:
        return _buildCupertinoLogTab(isDark);
    }
  }

  /// 显示 Cupertino 退出对话框
  void _showCupertinoExitDialog(BuildContext context, bool isDark) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('退出开发者模式'),
        content: const Text('确定要退出开发者模式吗？'),
        actions: [
          CupertinoDialogAction(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('确定'),
            onPressed: () {
              DeveloperModeService().disableDeveloperMode();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// 构建 Cupertino 日志标签页
  Widget _buildCupertinoLogTab(bool isDark) {
    return AnimatedBuilder(
      animation: DeveloperModeService(),
      builder: (context, child) {
        final logs = DeveloperModeService().logs;
        
        return Column(
          children: [
            // 工具栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '共 ${logs.length} 条日志',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.doc_on_clipboard, size: 22),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: logs.join('\n')));
                      _showCupertinoToast('已复制到剪贴板');
                    },
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(CupertinoIcons.trash, size: 22),
                    onPressed: () => DeveloperModeService().clearLogs(),
                  ),
                ],
              ),
            ),
            // 日志列表
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('暂无日志', style: TextStyle(color: CupertinoColors.systemGrey)))
                  : ListView.builder(
                      controller: _logScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: SelectableText(
                            log,
                            style: TextStyle(
                              fontFamily: 'Menlo',
                              fontSize: 12,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// 构建 Cupertino 数据标签页
  Widget _buildCupertinoDataTab(bool isDark) {
    return AnimatedBuilder(
      animation: AdminService(),
      builder: (context, child) {
        if (!AdminService().isAuthenticated) {
          return _buildCupertinoAdminLogin(isDark);
        } else {
          return _buildCupertinoAdminPanel(isDark);
        }
      },
    );
  }

  /// 构建 Cupertino 管理员登录
  Widget _buildCupertinoAdminLogin(bool isDark) {
    final passwordController = TextEditingController();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.shield_lefthalf_fill,
              size: 80,
              color: CupertinoColors.activeBlue,
            ),
            const SizedBox(height: 24),
            const Text(
              '管理员后台',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '需要验证管理员身份',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 48),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CupertinoTextField(
                controller: passwordController,
                obscureText: true,
                placeholder: '管理员密码',
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefix: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(CupertinoIcons.lock_fill, color: CupertinoColors.systemGrey, size: 20),
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                onSubmitted: (_) async {
                  await _handleAdminLogin(passwordController.text);
                  passwordController.clear();
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: AdminService().isLoading
                    ? null
                    : () async {
                        await _handleAdminLogin(passwordController.text);
                        passwordController.clear();
                      },
                child: AdminService().isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text('登录'),
              ),
            ),
            if (AdminService().errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                AdminService().errorMessage!,
                style: const TextStyle(color: CupertinoColors.destructiveRed),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建 Cupertino 管理员面板（简化版，显示用户列表）
  Widget _buildCupertinoAdminPanel(bool isDark) {
    return Column(
      children: [
        // 工具栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.refresh, size: 22),
                onPressed: AdminService().isLoading
                    ? null
                    : () async {
                        await AdminService().fetchUsers();
                        await AdminService().fetchStats();
                      },
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.square_arrow_right, size: 18),
                    const SizedBox(width: 4),
                    const Text('退出'),
                  ],
                ),
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('退出管理员'),
                      content: const Text('确定要退出管理员后台吗？'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('取消'),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text('确定'),
                          onPressed: () {
                            AdminService().logout();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // 用户列表
        Expanded(
          child: AdminService().isLoading && AdminService().users.isEmpty
              ? const Center(child: CupertinoActivityIndicator())
              : AdminService().users.isEmpty
                  ? const Center(child: Text('暂无用户数据', style: TextStyle(color: CupertinoColors.systemGrey)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: AdminService().users.length,
                      itemBuilder: (context, index) {
                        final user = AdminService().users[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.avatarUrl != null
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: user.avatarUrl == null
                                  ? Text(user.username[0].toUpperCase())
                                  : null,
                            ),
                            title: Row(
                              children: [
                                Text(user.username),
                                if (user.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(CupertinoIcons.checkmark_seal_fill, 
                                    color: CupertinoColors.activeGreen, size: 14),
                                ],
                              ],
                            ),
                            subtitle: Text(user.email),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  /// 构建 Cupertino 设置标签页
  Widget _buildCupertinoSettingsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 版本信息
        _buildCupertinoSettingsCard(
          isDark: isDark,
          icon: CupertinoIcons.info_circle_fill,
          title: '版本信息',
          subtitle: 'Cyrene Music v1.0.0',
        ),
        const SizedBox(height: 8),
        _buildCupertinoSettingsCard(
          isDark: isDark,
          icon: CupertinoIcons.chevron_left_slash_chevron_right,
          title: 'Flutter 版本',
          subtitle: '3.32.7',
        ),
        const SizedBox(height: 8),
        _buildCupertinoSettingsCard(
          isDark: isDark,
          icon: CupertinoIcons.device_phone_portrait,
          title: '平台',
          subtitle: _getPlatformName(),
        ),
        const SizedBox(height: 8),
        // 合并搜索结果开关
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CupertinoListTile(
            leading: const Icon(CupertinoIcons.arrow_merge, color: CupertinoColors.activeBlue),
            title: const Text('合并搜索结果'),
            subtitle: const Text('关闭后将分平台显示'),
            trailing: CupertinoSwitch(
              value: DeveloperModeService().isSearchResultMergeEnabled,
              onChanged: (value) {
                setState(() {
                  DeveloperModeService().toggleSearchResultMerge(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 性能叠加层开关
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CupertinoListTile(
            leading: const Icon(CupertinoIcons.graph_square, color: CupertinoColors.activeBlue),
            title: const Text('性能叠加层'),
            subtitle: const Text('显示帧率和渲染监控曲线'),
            trailing: CupertinoSwitch(
              value: DeveloperModeService().showPerformanceOverlay,
              onChanged: (value) {
                setState(() {
                  DeveloperModeService().togglePerformanceOverlay(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 测试按钮
        _buildCupertinoButton(
          label: '发送测试通知',
          icon: CupertinoIcons.bell_fill,
          onPressed: () async {
            await NotificationService().showNotification(
              id: 999,
              title: '测试通知',
              body: '这是一条来自开发者模式的测试通知',
            );
          },
        ),
        const SizedBox(height: 8),
        _buildCupertinoButton(
          label: '测试播放恢复通知',
          icon: CupertinoIcons.play_circle_fill,
          onPressed: () async {
            await _testPlaybackResumeNotification();
          },
        ),
        const SizedBox(height: 8),
        _buildCupertinoButton(
          label: '清除播放状态',
          icon: CupertinoIcons.trash_fill,
          color: CupertinoColors.systemOrange,
          onPressed: () async {
            await _clearPlaybackSession();
          },
        ),
        const SizedBox(height: 16),
        // WSA 专用
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'WSA 专用',
            style: TextStyle(
              color: CupertinoColors.activeBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildCupertinoButton(
          label: '快速登录',
          icon: CupertinoIcons.person_crop_circle_badge_checkmark,
          color: CupertinoColors.systemPurple,
          onPressed: () => _showCupertinoQuickLoginDialog(isDark),
        ),
      ],
    );
  }

  /// 构建 Cupertino 设置卡片
  Widget _buildCupertinoSettingsCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: CupertinoColors.activeBlue),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  /// 构建 Cupertino 按钮
  Widget _buildCupertinoButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: color ?? CupertinoColors.activeBlue,
        padding: const EdgeInsets.symmetric(vertical: 14),
        borderRadius: BorderRadius.circular(10),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: CupertinoColors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: CupertinoColors.white)),
          ],
        ),
      ),
    );
  }

  /// 显示 Cupertino 快速登录对话框
  void _showCupertinoQuickLoginDialog(bool isDark) {
    final accountController = TextEditingController();
    final passwordController = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.systemGroupedBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 拖动指示器
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey3,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '快速登录',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '直接输入账号密码登录（用于 WSA 等环境）',
                    style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // 账号输入框
                  CupertinoTextField(
                    controller: accountController,
                    placeholder: '邮箱 / 用户名',
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.person_fill, color: CupertinoColors.systemGrey, size: 20),
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 密码输入框
                  CupertinoTextField(
                    controller: passwordController,
                    placeholder: '密码',
                    obscureText: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(CupertinoIcons.lock_fill, color: CupertinoColors.systemGrey, size: 20),
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 登录按钮
                  CupertinoButton.filled(
                    onPressed: () async {
                      if (accountController.text.trim().isEmpty || passwordController.text.isEmpty) {
                        _showCupertinoToast('请输入账号和密码');
                        return;
                      }
                      
                      Navigator.pop(context);
                      
                      final result = await AuthService().login(
                        account: accountController.text.trim(),
                        password: passwordController.text,
                      );
                      
                      if (result['success']) {
                        _showCupertinoToast('✅ 登录成功', isSuccess: true);
                        AuthService().updateLocation();
                      } else {
                        _showCupertinoToast('登录失败: ${result['message']}');
                      }
                    },
                    child: const Text('登录'),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 显示 Cupertino Toast
  void _showCupertinoToast(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? CupertinoColors.activeGreen : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

