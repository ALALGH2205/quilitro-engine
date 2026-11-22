// Layar utama QUILITRO (desktop), meniru tampilan mobile:
// "Hubungkan ke perangkat lain" + "Perangkat ini" + daftar perangkat terbaru.
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
  // Controller yang sama seperti ConnectionPage bawaan, supaya kartu peer
  // (klik untuk mengisi ID) tetap berfungsi.
  final _idController = IDTextEditingController();
  final TextEditingController _idEditingController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final RxBool _svcStopped = Get.find<RxBool>(tag: 'stop-service');
  Timer? _statusTimer;
  bool _showMyPassword = false;
  bool? _autoAcceptOverride;

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
    _pwController.dispose();
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

  // ------------------------------------------------------------------ aksi
  bool _hasTarget() {
    if (_idController.id.isEmpty) {
      showToast('Masukkan ID perangkat tujuan');
      return false;
    }
    return true;
  }

  void _onConnect() {
    if (!_hasTarget()) return;
    final pw = _pwController.text;
    connect(context, _idController.id, password: pw.isEmpty ? null : pw);
  }

  void _onSendFile() {
    if (!_hasTarget()) return;
    final pw = _pwController.text;
    connect(context, _idController.id,
        isFileTransfer: true, password: pw.isEmpty ? null : pw);
  }

  Future<void> _onSave() async {
    if (!_hasTarget()) return;
    final id = _idController.id;
    try {
      final favs = (await bind.mainGetFav()).toList();
      if (!favs.contains(id)) {
        favs.add(id);
        await bind.mainStoreFav(favs: favs);
      }
      showToast('Disimpan ke Favorit');
    } catch (e) {
      showToast('Gagal menyimpan');
    }
  }

  Future<void> _setAutoAccept(bool v) async {
    setState(() => _autoAcceptOverride = v);
    await bind.mainSetOption(key: 'approve-mode', value: v ? 'password' : 'click');
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _autoAcceptOverride = null);
  }

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    return QuilitroBackground(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final body = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _connectCard(context),
                        const SizedBox(height: 18),
                        Expanded(child: _recentCard(context)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 360,
                    child: SingleChildScrollView(child: _deviceCard(context)),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _connectCard(context),
                    const SizedBox(height: 18),
                    _deviceCard(context),
                    const SizedBox(height: 18),
                    SizedBox(height: 420, child: _recentCard(context)),
                  ],
                ),
              );
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            children: [
              _header(context),
              const SizedBox(height: 14),
              _errorNotice(context),
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
          icon: Icon(Icons.settings_outlined, color: qText(context), size: 26),
          onPressed: () => DesktopTabPage.onAddSetting(),
        ),
      ],
    );
  }

  Widget _errorNotice(BuildContext context) {
    if (widget.systemError.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        radius: 20,
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: QColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(translate(widget.systemError),
                style: TextStyle(color: qText(context))),
          ),
        ]),
      ),
    );
  }

  // ------------------------------------------------- Hubungkan ke perangkat lain
  Widget _connectCard(BuildContext context) {
    final fieldStyle = TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: qText(context),
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QCardTitle('Hubungkan ke perangkat lain'),
          const SizedBox(height: 16),
          TextField(
            controller: _idController,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            inputFormatters: [IDTextInputFormatter()],
            style: fieldStyle,
            cursorColor: QColors.gold,
            decoration: qInputDecoration(context, hint: 'ID perangkat tujuan'),
            onSubmitted: (_) => _onConnect(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pwController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            style: fieldStyle,
            cursorColor: QColors.gold,
            decoration: qInputDecoration(context, hint: 'Password'),
            onSubmitted: (_) => _onConnect(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              text: 'Hubungkan',
              icon: Icons.cast_connected_rounded,
              onPressed: _onConnect,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GoldButton(
                text: 'Kirim file',
                icon: Icons.folder_open_outlined,
                outlined: true,
                onPressed: _onSendFile,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GoldButton(
                text: 'Simpan',
                icon: Icons.bookmark_add_outlined,
                outlined: true,
                onPressed: _onSave,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Perangkat ini
  Widget _deviceCard(BuildContext context) {
    final sub = TextStyle(fontSize: 15, color: qSubText(context));
    return ChangeNotifierProvider.value(
      value: gFFI.serverModel,
      child: Consumer<ServerModel>(builder: (context, model, _) {
        final showOneTime = model.approveMode != 'click' &&
            model.verificationMethod != kUsePermanentPassword;
        final autoAccept =
            _autoAcceptOverride ?? (model.approveMode == 'password');
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const QCardTitle('Perangkat ini'),
              const SizedBox(height: 18),
              Text('ID Anda', style: sub),
              const SizedBox(height: 2),
              Row(children: [
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: model.serverId,
                    builder: (_, v, __) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        v.text.isEmpty ? '...' : v.text,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: QColors.gold,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Salin ID',
                  icon: Icon(Icons.copy_rounded, color: qSubText(context)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: model.serverId.text));
                    showToast(translate('Copied'));
                  },
                ),
              ]),
              const SizedBox(height: 14),
              Text('Password', style: sub),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: model.serverPasswd,
                    builder: (_, v, __) => Text(
                      v.text.isEmpty
                          ? '-'
                          : (_showMyPassword ? v.text : '\u2022' * 8),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: qText(context),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _showMyPassword ? 'Sembunyikan' : 'Tampilkan',
                  icon: Icon(
                    _showMyPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: qSubText(context),
                  ),
                  onPressed: () =>
                      setState(() => _showMyPassword = !_showMyPassword),
                ),
                if (showOneTime)
                  IconButton(
                    tooltip: 'Password baru',
                    icon: Icon(Icons.refresh_rounded,
                        color: qSubText(context)),
                    onPressed: () => bind.mainUpdateTemporaryPassword(),
                  ),
                IconButton(
                  tooltip: 'Atur password tetap',
                  icon: Icon(Icons.edit_outlined, color: qSubText(context)),
                  onPressed: () =>
                      DesktopSettingPage.switch2page(SettingsTabKey.safety),
                ),
              ]),
              const Divider(height: 28),
              QSwitchRow(
                title: 'Terima koneksi otomatis',
                subtitle: 'Tanpa konfirmasi jika password benar',
                value: autoAccept,
                onChanged: _setAutoAccept,
              ),
              const SizedBox(height: 14),
              _adminRow(context),
              const SizedBox(height: 16),
              _status(context),
            ],
          ),
        );
      }),
    );
  }

  Widget _adminRow(BuildContext context) {
    if (!isWindows) return const SizedBox();
    final sub = TextStyle(fontSize: 13, color: qSubText(context));
    if (bind.mainIsInstalled()) {
      return Row(children: [
        const Icon(Icons.verified_user_outlined,
            color: Color(0xFF32BEA6), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Akses penuh (administrator)',
                  style: TextStyle(fontSize: 17, color: qText(context))),
              const SizedBox(height: 3),
              Text('Aktif: jendela administrator juga bisa dikontrol',
                  style: sub),
            ],
          ),
        ),
      ]);
    }
    if (bind.isDisableInstallation()) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Akses penuh (administrator)',
            style: TextStyle(fontSize: 17, color: qText(context))),
        const SizedBox(height: 3),
        Text('Pasang QUILITRO agar jendela administrator bisa dikontrol',
            style: sub),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: GoldButton(
            text: 'Pasang sekarang',
            icon: Icons.download_rounded,
            outlined: true,
            onPressed: () async {
              await rustDeskWinManager.closeAllSubWindows();
              bind.mainGotoInstall();
            },
          ),
        ),
      ],
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

  // ------------------------------------------------------------------ Terbaru
  Widget _recentCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: PeerTabPage(),
    );
  }
}
