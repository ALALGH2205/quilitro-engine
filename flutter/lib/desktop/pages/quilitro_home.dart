// Layar utama QUILITRO (desktop): "Perangkat ini" + "Hubungkan" + daftar terbaru.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/quilitro_ui.dart';
import 'package:flutter_hbb/common/widgets/peer_tab_page.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class QuilitroDesktopHome extends StatefulWidget {
  const QuilitroDesktopHome({Key? key, this.systemError = ''})
      : super(key: key);

  final String systemError;

  @override
  State<QuilitroDesktopHome> createState() => _QuilitroDesktopHomeState();
}

class _QuilitroDesktopHomeState extends State<QuilitroDesktopHome> {
  // Controller ID yang sama seperti di ConnectionPage bawaan, supaya kartu
  // peer (klik untuk mengisi ID) tetap berfungsi.
  final _idController = IDTextEditingController();
  final TextEditingController _idEditingController = TextEditingController();
  final RxBool _svcStopped = Get.find<RxBool>(tag: 'stop-service');
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    Get.put<TextEditingController>(_idEditingController);
    Get.put<IDTextEditingController>(_idController);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final last = await bind.mainGetLastRemoteId();
      if (mounted && _idController.text.isEmpty && last != _idController.id) {
        setState(() => _idController.id = last);
      }
    });
    _statusTimer = periodic_immediate(const Duration(seconds: 1), _updateStatus);
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _idController.dispose();
    _idEditingController.dispose();
    if (Get.isRegistered<IDTextEditingController>()) {
      Get.delete<IDTextEditingController>();
    }
    if (Get.isRegistered<TextEditingController>()) {
      Get.delete<TextEditingController>();
    }
    super.dispose();
  }

  Future<void> _updateStatus() async {
    try {
      final status =
          jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
      final n = status['status_num'] as int;
      stateGlobal.svcStatus.value = n == 0
          ? SvcStatus.connecting
          : (n == 1 ? SvcStatus.ready : SvcStatus.notReady);
    } catch (_) {}
  }

  void _onConnect() {
    final id = _idController.id;
    if (id.isEmpty) {
      showToast('Masukkan ID perangkat tujuan');
      return;
    }
    connect(context, id);
  }

  void _onSendFile() {
    final id = _idController.id;
    if (id.isEmpty) {
      showToast('Masukkan ID perangkat tujuan');
      return;
    }
    connect(context, id, isFileTransfer: true);
  }

  @override
  Widget build(BuildContext context) {
    return QuilitroBackground(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 820;
        final body = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320,
                    child: SingleChildScrollView(child: _deviceCard(context)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _connectCard(context),
                        const SizedBox(height: 16),
                        Expanded(child: _recentCard(context)),
                      ],
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _deviceCard(context),
                    const SizedBox(height: 16),
                    _connectCard(context),
                    const SizedBox(height: 16),
                    SizedBox(height: 420, child: _recentCard(context)),
                  ],
                ),
              );
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 14),
              _notices(context),
              Expanded(child: body),
            ],
          ),
        );
      }),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const QuilitroWordmark(),
        const Spacer(),
        const ThemeToggleButton(),
        IconButton(
          tooltip: 'Pengaturan',
          icon: Icon(Icons.settings_outlined, color: qText(context)),
          onPressed: () => DesktopTabPage.onAddSetting(),
        ),
      ],
    );
  }

  Widget _notices(BuildContext context) {
    final children = <Widget>[];
    if (widget.systemError.isNotEmpty) {
      children.add(GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: QColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(translate(widget.systemError),
                style: TextStyle(color: qText(context))),
          ),
        ]),
      ));
    }
    if (isWindows && !bind.isDisableInstallation() && !bind.mainIsInstalled()) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 10));
      children.add(GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: Text(
              'QUILITRO belum dipasang di PC ini. Pasang agar bisa dikontrol '
              'penuh (termasuk jendela administrator).',
              style: TextStyle(color: qText(context)),
            ),
          ),
          const SizedBox(width: 12),
          GoldButton(
            text: 'Pasang',
            icon: Icons.download_rounded,
            onPressed: () async {
              await rustDeskWinManager.closeAllSubWindows();
              bind.mainGotoInstall();
            },
          ),
        ]),
      ));
    }
    if (children.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(children: children),
    );
  }

  // ---------------------------------------------------------------- Perangkat ini
  Widget _deviceCard(BuildContext context) {
    final sub = TextStyle(fontSize: 13, color: qSubText(context));
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(builder: (context, model, _) {
        final showOneTime = model.approveMode != 'click' &&
            model.verificationMethod != kUsePermanentPassword;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QCardTitle('Perangkat ini', Icons.computer_rounded),
              const SizedBox(height: 8),
              Text('Berikan ID dan kata sandi ini kepada orang yang akan '
                  'mengontrol perangkat ini.', style: sub),
              const SizedBox(height: 18),
              Text('ID', style: sub),
              Row(children: [
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: model.serverId,
                    builder: (_, v, __) => Text(
                      v.text.isEmpty ? '...' : v.text,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: qText(context),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Salin ID',
                  icon: const Icon(Icons.copy_rounded, color: QColors.gold),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: model.serverId.text));
                    showToast(translate('Copied'));
                  },
                ),
              ]),
              const SizedBox(height: 10),
              Text('Kata sandi', style: sub),
              Row(children: [
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: model.serverPasswd,
                    builder: (_, v, __) => Text(
                      v.text.isEmpty ? '-' : v.text,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: qText(context),
                      ),
                    ),
                  ),
                ),
                if (showOneTime)
                  IconButton(
                    tooltip: 'Kata sandi baru',
                    icon: const Icon(Icons.refresh_rounded,
                        color: QColors.gold),
                    onPressed: () => bind.mainUpdateTemporaryPassword(),
                  ),
              ]),
              const SizedBox(height: 14),
              GoldButton(
                text: 'Atur kata sandi tetap',
                icon: Icons.key_rounded,
                outlined: true,
                onPressed: () =>
                    DesktopSettingPage.switch2page(SettingsTabKey.safety),
              ),
              const SizedBox(height: 16),
              _status(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _status(BuildContext context) {
    return Obx(() {
      final stopped = _svcStopped.value;
      final s = stateGlobal.svcStatus.value;
      final Color dot;
      final String label;
      if (stopped) {
        dot = kColorWarn;
        label = 'Layanan berhenti';
      } else if (s == SvcStatus.connecting) {
        dot = kColorWarn;
        label = 'Menghubungkan ke server...';
      } else if (s == SvcStatus.ready) {
        dot = const Color(0xFF32BEA6);
        label = 'Siap dikontrol';
      } else {
        dot = const Color(0xFFE04F5F);
        label = 'Belum siap, periksa internet';
      }
      return Row(children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: qSubText(context))),
        ),
        if (stopped) ...[
          const SizedBox(width: 10),
          InkWell(
            onTap: () async => await start_service(true),
            child: const Text('Mulai layanan',
                style: TextStyle(
                  fontSize: 13,
                  color: QColors.gold,
                  decoration: TextDecoration.underline,
                )),
          ),
        ],
      ]);
    });
  }

  // ---------------------------------------------------------------- Hubungkan
  Widget _connectCard(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QCardTitle('Hubungkan', Icons.connected_tv_rounded),
          const SizedBox(height: 14),
          TextField(
            controller: _idController,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [IDTextInputFormatter()],
            style: TextStyle(
              fontFamily: 'WorkSans',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: qText(context),
            ),
            cursorColor: QColors.gold,
            decoration: qInputDecoration(context, hint: 'ID perangkat tujuan'),
            onSubmitted: (_) => _onConnect(),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: GoldButton(
                text: 'Hubungkan',
                icon: Icons.arrow_forward_rounded,
                onPressed: _onConnect,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GoldButton(
                text: 'Kirim file',
                icon: Icons.upload_file_rounded,
                outlined: true,
                onPressed: _onSendFile,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Terbaru
  Widget _recentCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: PeerTabPage(),
    );
  }
}
