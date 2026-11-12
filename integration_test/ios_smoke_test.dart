import 'package:airgapped_zcash_signer/main.dart' as app;
import 'package:airgapped_zcash_signer/src/app.dart';
import 'package:airgapped_zcash_signer/src/security/seed_vault.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('imports into iOS Keychain and exports an account through Rust', (
    tester,
  ) async {
    const vault = SeedVault();
    expect(
      await vault.isProvisioned,
      isFalse,
      reason: 'Run this test on a fresh, isolated simulator app.',
    );
    // Public zero-entropy fixture. Never use this recovery phrase for funds.
    final phrase = bip39.entropyToMnemonic('0' * 64);
    addTearDown(vault.delete);
    Future<void> reveal(Finder target) => tester.scrollUntilVisible(
      target,
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('Wallet not set up'), findsOneWidget);

    await reveal(find.text('Set up testnet wallet'));
    await tester.tap(find.text('Set up testnet wallet'));
    await tester.pumpAndSettle();
    await reveal(find.byType(TextField));
    await tester.enterText(find.byType(TextField), phrase);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await reveal(find.text('Import existing wallet'));
    await tester.tap(find.text('Import existing wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Testnet key ready'), findsOneWidget);

    // Recreate the app tree to exercise bootstrap from native persisted data.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const SignerApp());
    await tester.pumpAndSettle();
    expect(find.text('Testnet key ready'), findsOneWidget);
    expect(find.text('Seed protected by iOS Keychain'), findsOneWidget);

    await reveal(find.text('Connect to Vizor Desktop'));
    await tester.tap(find.text('Connect to Vizor Desktop'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('QR 1 of '), findsOneWidget);
  });
}
