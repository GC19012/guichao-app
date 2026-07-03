import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fpdart/fpdart.dart';
import 'package:gap/gap.dart';
import 'package:guichao/gch_gen/gch_text.dart';
import 'package:guichao/gch_base/gch_schema/gch_fault.dart';
import 'package:guichao/gch_base/gch_prefs/gch_general_pref.dart';
import 'package:guichao/gch_base/gch_widget/gch_icon.dart';
import 'package:guichao/gch_mod/gch_shared/gch_nested_app_bar.dart';
import 'package:guichao/gch_mod/gch_log/gch_repo/gch_log_data_providers.dart';
import 'package:guichao/gch_mod/gch_log/gch_model/gch_log_level.dart';
import 'package:guichao/gch_mod/gch_log/gch_browse/gch_logs_overview_notifier.dart';
import 'package:guichao/gch_aux/gch_common.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class LogsOverviewPage extends HookConsumerWidget with GchPresLogger {
  const LogsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gchLogBrowseNotifierProvider);
    final notifier = ref.watch(gchLogBrowseNotifierProvider.notifier);

    final debug = ref.watch(gchDebugModeProvider);
    final pathResolver = ref.watch(gchTraceLocatorProvider);

    final filterController = useTextEditingController(text: state.filter);

    final List<PopupMenuEntry> popupButtons = debug
        ? [
            PopupMenuItem(
              child: Text(GchText.logDataShareCoreLogs),
              onTap: () async {
                final coreFile = await pathResolver.coreFile();
                await UriUtils.tryShareOrLaunchFile(
                  Uri.parse(coreFile.path),
                  fileOrDir: pathResolver.directory.uri,
                );
              },
            ),
            PopupMenuItem(
              child: Text(GchText.logDataShareAppLogs),
              onTap: () async {
                await UriUtils.tryShareOrLaunchFile(
                  Uri.parse(pathResolver.appFile().path),
                  fileOrDir: pathResolver.directory.uri,
                );
              },
            ),
          ]
        : [];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return <Widget>[
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: MultiSliver(
                children: [
                  NestedAppBar(
                    forceElevated: innerBoxIsScrolled,
                    title: Text(GchText.logDataPageTitle),
                    actions: [
                      if (state.paused)
                        IconButton(
                          onPressed: notifier.resume,
                          icon: const Icon(Icons.play_arrow),
                          tooltip: GchText.logDataResumeTooltip,
                          iconSize: 20,
                        )
                      else
                        IconButton(
                          onPressed: notifier.pause,
                          icon: const Icon(Icons.pause),
                          tooltip: GchText.logDataPauseTooltip,
                          iconSize: 20,
                        ),
                      IconButton(
                        onPressed: notifier.clear,
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: GchText.logDataClearTooltip,
                        iconSize: 20,
                      ),
                      if (popupButtons.isNotEmpty)
                        PopupMenuButton(
                          icon: Icon(GchIcon(context).more),
                          itemBuilder: (context) {
                            return popupButtons;
                          },
                        ),
                    ],
                  ),
                  SliverPinnedHeader(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Flexible(
                              child: TextFormField(
                                controller: filterController,
                                onChanged: notifier.filterMessage,
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: GchText.logDataFilterHint,
                                ),
                              ),
                            ),
                            const Gap(16),
                            DropdownButton<Option<GchLogLevel>>(
                              value: optionOf(state.levelFilter),
                              onChanged: (v) {
                                if (v == null) return;
                                notifier.filterLevel(v.toNullable());
                              },
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              borderRadius: BorderRadius.circular(4),
                              items: [
                                DropdownMenuItem(
                                  value: none(),
                                  child: Text(GchText.logDataAllLevelsFilter),
                                ),
                                ...GchLogLevel.choices.map(
                                  (e) => DropdownMenuItem(
                                    value: some(e),
                                    child: Text(e.name),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: Builder(
          builder: (context) {
            return CustomScrollView(
              primary: false,
              reverse: true,
              slivers: <Widget>[
                switch (state.logs) {
                  AsyncData(value: final logs) => SliverList.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (log.level != null)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          log.level!.name.toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: log.level!.color,
                                              ),
                                        ),
                                        if (log.time != null)
                                          Text(
                                            log.time!.toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                      ],
                                    ),
                                  Text(
                                    log.message,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (index != 0)
                              const Divider(
                                indent: 16,
                                endIndent: 16,
                                height: 4,
                              ),
                          ],
                        );
                      },
                    ),
                  AsyncError(:final error) => GchSliverErrBody(
                      GchFaultPresenter.briefFault(error),
                    ),
                  _ => const GchSliverLoadBody(),
                },
                SliverOverlapInjector(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
