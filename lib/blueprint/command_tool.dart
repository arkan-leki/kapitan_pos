import 'dart:typed_data';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';

/// CommandTool
class CommandTool {
  static final tscCommand = TscCommand();
  static final cpclCommand = CpclCommand();
  static final escCommand = EscCommand();

  /// tscSelfTestCmd
  static Future<Uint8List?> tscSelfTestCmd() async {
    await tscCommand.cleanCommand();
    await tscCommand.selfTest();
    final cmd = await tscCommand.getCommand();
    return cmd;
  }

  /// tscImageCmd
  static Future<Uint8List?> tscImageCmd(Uint8List image) async {
    await tscCommand.cleanCommand();
    await tscCommand.size(width: 76, height: 130);
    await tscCommand.cls(); // most after size
    await tscCommand.image(image: image, x: 50, y: 60);
    await tscCommand.print(1);
    final cmd = await tscCommand.getCommand();
    return cmd;
  }

  /// tscTemplateCmd
  static Future<Uint8List?> tscTemplateCmd() async {
    await tscCommand.cleanCommand();
    await tscCommand.size(width: 76, height: 130);
    await tscCommand.cls(); // most after size
    await tscCommand.speed(8);
    await tscCommand.density(8);
    await tscCommand.text(content: "莫听穿林打叶声，何妨吟啸且徐行。", x: 10, y: 10);
    await tscCommand.text(
      content: "竹杖芒鞋轻胜马，谁怕？",
      x: 10,
      y: 60,
      xMulti: 2,
      yMulti: 2,
    );
    await tscCommand.text(
      content: "一蓑烟雨任平生。",
      x: 10,
      y: 170,
      xMulti: 3,
      yMulti: 3,
    );
    await tscCommand.qrCode(
      // content: "料峭春风吹酒醒，微冷，山头斜照却相迎。",
      content: "28938928",
      x: 50,
      y: 350,
      cellWidth: 3,
    );
    await tscCommand.qrCode(
      // content: "回首向来萧瑟处，归去，也无风雨也无晴。",
      content: "28938928",
      x: 50,
      y: 500,
    );
    await tscCommand.barCode(content: "123456789", x: 200, y: 350);
    await tscCommand.print(1);
    final cmd = await tscCommand.getCommand();
    return cmd;
  }

  /// cpclImageCmd
  static Future<Uint8List?> cpclImageCmd(Uint8List image) async {
    await cpclCommand.cleanCommand();
    await cpclCommand.size(width: 76 * 8, height: 76 * 8);
    await cpclCommand.image(image: image, x: 10, y: 10);
    await cpclCommand
        .form(); // After printing is complete, locate it at the top of the next page.
    await cpclCommand.print();
    final cmd = await cpclCommand.getCommand();
    return cmd;
  }

  /// cpclTemplateCmd
  static Future<Uint8List?> cpclTemplateCmd() async {
    await cpclCommand.cleanCommand();
    await cpclCommand.size(width: 76 * 8, height: 76 * 8);
    await cpclCommand.qrCode(content: "12345678", x: 10, y: 10, width: 8);
    await cpclCommand.barCode(content: "12345678", x: 10, y: 190);
    await cpclCommand.text(content: "日啖荔枝三百颗", x: 10, y: 300);
    await cpclCommand.text(
      content: "不辞长作岭南人",
      x: 10,
      y: 330,
      bold: true,
      xMulti: 2,
      yMulti: 2,
    );
    await cpclCommand.line(x: 300, y: 100, endX: 360, endY: 500);
    await cpclCommand
        .form(); // After printing is complete, locate it at the top of the next page.
    await cpclCommand.print();
    final cmd = await cpclCommand.getCommand();
    return cmd;
  }

  /// escImageCmd
  static Future<Uint8List?> escImageCmd(Uint8List image) async {
    await escCommand.cleanCommand();
    await escCommand.print();
    await escCommand.image(image: image);
    await escCommand.print();
    final cmd = await escCommand.getCommand();
    return cmd;
  }

  static Future<Uint8List?> escTemplateCmd() async {
    await escCommand.cleanCommand();
    await escCommand.print(feedLines: 5);
    await escCommand.newline();
    await escCommand.text(content: "hello world");
    await escCommand.newline();
    await escCommand.text(
      content: "hello flutter",
      alignment: Alignment.center,
      style: EscTextStyle.underline,
      fontSize: EscFontSize.size3,
    );
    await escCommand.newline();
    await escCommand.code128(content: "123456");
    await escCommand.newline();
    await escCommand.qrCode(content: "this is qrcode");
    await escCommand.print(feedLines: 5);
    final cmd = await escCommand.getCommand();
    return cmd;
  }

  static Future<Uint8List?> escCardCmd(
    List<Map<String, dynamic>> printData,
  ) async {
    await escCommand.cleanCommand();
    await escCommand.print(feedLines: 3);

    for (var card in printData) {
      await escCommand.text(
        content: 'Fany Pizza POS',
        alignment: Alignment.center,
        style: EscTextStyle.bold,
      );
      await escCommand.newline();
      await escCommand.text(content: '---------------------------');
      await escCommand.newline();
      await escCommand.text(content: 'Series: ${card['series']}');
      await escCommand.newline();
      await escCommand.text(content: 'Office: ${card['city']}');
      await escCommand.newline();
      await escCommand.text(content: 'Mobile: ${card['mobile']}');
      await escCommand.newline();
      await escCommand.text(content: 'Date: ${card['updated_at']}');
      await escCommand.newline();
      await escCommand.text(content: '---------------------------');
      await escCommand.newline();
      await escCommand.text(content: 'CODE/USER: ${card['pin']}');
      await escCommand.newline();
      await escCommand.text(content: 'Password: ${card['price']}');
      await escCommand.newline();
      // await escCommand.qrCode(content: card['pin'].toString(),alignment: Alignment.center,size: 10);
      // await escCommand.newline();
      await escCommand.text(content: '---------------------------');
      await escCommand.newline();
      await escCommand.cutPaper();
    }

    await escCommand.print(feedLines: 2);
    return await escCommand.getCommand();
  }

  static Future<Uint8List?> tscCardCmd(
    List<Map<String, dynamic>> printData,
  ) async {
    await tscCommand.cleanCommand();

    for (var card in printData) {
      await tscCommand.size(width: 76, height: 130); // mm
      await tscCommand.cls();
      await tscCommand.speed(8);
      await tscCommand.density(8);

      await tscCommand.text(content: 'ID: ${card['id']}', x: 10, y: 10);
      await tscCommand.text(content: 'PIN: ${card['pin']}', x: 10, y: 50);
      await tscCommand.text(content: 'Serial: ${card['serial']}', x: 10, y: 90);
      await tscCommand.text(content: 'City: ${card['city']}', x: 10, y: 130);
      await tscCommand.text(content: 'Price: ${card['price']}', x: 10, y: 170);
      await tscCommand.text(
        content: 'Mobile: ${card['mobile']}',
        x: 10,
        y: 210,
      );
      await tscCommand.text(
        content: 'Updated: ${card['updated_at']}',
        x: 10,
        y: 250,
      );
      await tscCommand.text(
        content: 'Series: ${card['series']}',
        x: 10,
        y: 290,
      );

      await tscCommand.barCode(content: card['pin'], x: 20, y: 350);

      await tscCommand.print(1); // one copy
    }

    final cmd = await tscCommand.getCommand();
    return cmd;
  }

  // --- New method for printing food receipts ---
  static Future<Uint8List?> escFoodReceiptCmd(
    List<Map<String, dynamic>> printData,
  ) async {
    await escCommand.cleanCommand();
    await escCommand.print(feedLines: 3);

    for (var order in printData) {
      await escCommand.text(
        content: '--- Fancy Pizza Order ---',
        alignment: Alignment.center,
        style: EscTextStyle.bold,
      );
      await escCommand.newline();
      await escCommand.text(content: 'Order ID: ${order['id']}');
      await escCommand.newline();
      await escCommand.text(content: 'Order Type: ${order['subtitle']}');
      await escCommand.newline();
      await escCommand.text(content: 'Date: ${order['date']}');
      await escCommand.newline();
      await escCommand.text(content: '--------------------------------');
      await escCommand.newline();
      await escCommand.text(
        content: 'Item                Qty   Price',
        style: EscTextStyle.bold,
      );
      await escCommand.newline();
      await escCommand.text(content: '--------------------------------');
      await escCommand.newline();

      for (var item in order['items']) {
        final itemName = item['name'].toString().padRight(20).substring(0, 20);
        final quantity = item['quantity'].toString().padLeft(3);
        final price = item['price'].toStringAsFixed(2).padLeft(7);
        await escCommand.text(content: '$itemName $quantity   $price');
        await escCommand.newline();
      }

      await escCommand.text(content: '--------------------------------');
      await escCommand.newline();
      await escCommand.text(
        content: 'Total: ${order['total']}',
        alignment: Alignment.right,
        style: EscTextStyle.bold,
        fontSize: EscFontSize.size2,
      );
      await escCommand.newline();
      await escCommand.text(content: 'Thank You!', alignment: Alignment.center);
      await escCommand.newline();
      await escCommand.cutPaper(); // Cut paper after each receipt
    }

    await escCommand.print(feedLines: 2); // Add some space at the end
    return await escCommand.getCommand();
  }

  static Future<Uint8List?> tscFoodReceiptCmd(
    List<Map<String, dynamic>> printData,
  ) async {
    await tscCommand.cleanCommand();

    for (var order in printData) {
      await tscCommand.size(width: 76, height: 130);
      await tscCommand.cls();
      await tscCommand.speed(8);
      await tscCommand.density(8);

      // Header with more space
      await tscCommand.text(
        content: 'FANCY PIZZA ORDER',
        x: 100,
        y: 15,
        xMulti: 1,
        yMulti: 1,
      );

      await tscCommand.text(
        content: '-------------------------------',
        x: 10,
        y: 50,
      );

      // Order info with increased spacing
      await tscCommand.text(
        content: 'Order: ${order['order_title']}',
        x: 10,
        y: 100,
      );
      await tscCommand.text(
        content: 'Type: ${order['order_type']}',
        x: 10,
        y: 140,
      );
      await tscCommand.text(content: 'Date: ${order['date']}', x: 10, y: 180);

      await tscCommand.text(
        content: 'Phone: ${order['customer_name']}',
        x: 10,
        y: 220,
      );
      await tscCommand.text(
        content: 'Address: ${order['delivery_address']}',
        x: 10,
        y: 250,
      );

      // Divider with more space
      await tscCommand.text(
        content: '-------------------------------',
        x: 10,
        y: 300,
      );

      // Column headers with space
      await tscCommand.text(content: 'ITEM', x: 10, y: 350);
      await tscCommand.text(content: 'QTY', x: 200, y: 350);
      await tscCommand.text(content: 'PRICE', x: 300, y: 350);

      // Divider with space
      await tscCommand.text(
        content: '-------------------------------',
        x: 10,
        y: 380,
      );

      // Items list with more spacing
      int yPos = 400;
      for (var item in order['items']) {
        String itemName = item['name'].toString();
        if (itemName.length > 20) {
          itemName = itemName.substring(0, 17) + '...';
        }

        await tscCommand.text(content: itemName, x: 10, y: yPos);
        await tscCommand.text(
          content: item['quantity'].toString(),
          x: 200,
          y: yPos,
        );
        await tscCommand.text(
          content: item['price'].toString(),
          x: 280,
          y: yPos,
        );

        yPos += 30; // More space between items
      }

      // Total section with more space
      await tscCommand.text(
        content: '-------------------------------',
        x: 10,
        y: yPos + 15,
      );

      yPos += 40;
      await tscCommand.text(content: 'TOTAL:', x: 100, y: yPos);
      await tscCommand.text(
        content: order['total'].toString(),
        x: 200,
        y: yPos,
      );

      // Footer with maximum space
      yPos += 50;
      await tscCommand.text(
        content: 'Thank you for your order!',
        x: 40,
        y: yPos,
      );

      yPos += 40;
      await tscCommand.text(content: 'Visit us again soon', x: 40, y: yPos);

      await tscCommand.print(1);
    }

    return await tscCommand.getCommand();
  }
}
