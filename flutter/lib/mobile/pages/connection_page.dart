import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common/formatter/id_formatter.dart';
import 'package:flutter_hbb/common/quilitro_ui.dart';
import 'package:flutter_hbb/common/widgets/peer_tab_page.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../consts.dart';
import '../../models/platform_model.dart';
import 'home_page.dart';

/// Layar "Hubungkan" QUILITRO (Android).
class ConnectionPage extends StatefulWidget implements PageShape {
  ConnectionPage({Key? key, required this.appBarActions}) : super(key: key);

  @override
  final icon = const Icon(Icons.connected_tv);

  @override
  final title = translate("Connection");

  @override
  final List<Widget> appBarActions;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final _idController = IDTextEditingController();
  final TextEditingController _idEditingController = TextEditingController();
  StreamSubscription? _uniLinksSubscription;

  _ConnectionPageState() {
    if (!isWeb) _uniLinksSubscription = listenUniLinks();
    Get.put<IDTextEditingController>(_idController);
  }

  @override
  void initState() {
    super.initState();
    if (_idController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final lastRemoteId = await bind.mainGetLastRemoteId();
        if (mounted && lastRemoteId != _idController.id) {
          setState(() {
            _idController.id = lastRemoteId;
          });
        }
      });
    }
    Get.put<TextEditingController>(_idEditingController);
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
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: kMobilePageConstraints,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            children: [
              Row(
                children: const [
                  QuilitroWordmark(),
                  Spacer(),
                  ThemeToggleButton(),
                ],
              ),
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const QCardTitle('Hubungkan', Icons.connected_tv_rounded),
                    const SizedBox(height: 12),
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
                      decoration: qInputDecoration(context,
                          hint: 'ID perangkat tujuan'),
                      onSubmitted: (_) => _onConnect(),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: GoldButton(
                          text: 'Hubungkan',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _onConnect,
                        ),
                      ),
                      const SizedBox(width: 10),
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
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                  child: PeerTabPage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uniLinksSubscription?.cancel();
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
}
