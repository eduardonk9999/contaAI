import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ContaAiApp());
const apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3333',
);

class Api {
  static Future<dynamic> get(String path) async =>
      _read(await http.get(Uri.parse('$apiUrl$path')));
  static Future<dynamic> post(String path, Map<String, dynamic> body) async =>
      _read(
        await http.post(
          Uri.parse('$apiUrl$path'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        ),
      );
  static dynamic _read(http.Response response) {
    final value = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(value['error']?['message'] ?? 'Erro na API');
    }
    return value['data'];
  }
}

String brl(num cents) =>
    'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

class ContaAiApp extends StatelessWidget {
  const ContaAiApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ContAI',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      scaffoldBackgroundColor: const Color(0xFFF4F8FF),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDCE7F8)),
        ),
      ),
    ),
    home: const Shell(),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int selected = 0, refresh = 0;
  void go(int value) => setState(() => selected = value);
  void confirmed() => setState(() {
    refresh++;
    selected = 0;
  });
  @override
  Widget build(BuildContext context) {
    final pages = [
      Dashboard(key: ValueKey('d$refresh'), sell: () => go(2)),
      Stock(key: ValueKey('s$refresh')),
      Sale(done: confirmed),
      const About(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 780;
    return Scaffold(
      body: Row(
        children: [
          if (wide) SideNav(selected: selected, go: go),
          Expanded(child: SafeArea(child: pages[selected])),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: go,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'Estoque',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline),
                  label: 'Venda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.info_outline),
                  label: 'Sobre',
                ),
              ],
            ),
    );
  }
}

class SideNav extends StatelessWidget {
  const SideNav({super.key, required this.selected, required this.go});
  final int selected;
  final ValueChanged<int> go;
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.grid_view_rounded, 'Início'),
      (Icons.inventory_2_outlined, 'Estoque'),
      (Icons.add_circle_outline, 'Registrar venda'),
      (Icons.info_outline, 'Sobre'),
    ];
    return Container(
      width: 230,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Cont',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text: 'AI',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                selected: i == selected,
                selectedTileColor: const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(items[i].$1),
                title: Text(items[i].$2),
                onTap: () => go(i),
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                CircleAvatar(child: Text('E')),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eduardo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Plano piloto',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Frame extends StatelessWidget {
  const Frame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 25),
            child,
          ],
        ),
      ),
    ),
  );
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.sell});
  final VoidCallback sell;
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: Future.wait([
      Api.get('/v1/dashboard/summary'),
      Api.get('/v1/transactions'),
    ]),
    builder: (context, snapshot) => Frame(
      title: 'Olá, Eduardo 👋',
      subtitle: 'Aqui está o resumo da sua loja hoje.',
      child: state(snapshot, (data) {
        final summary = data[0], transactions = data[1] as List;
        final metrics = [
          (
            'Faturamento',
            brl(summary['sales_revenue_cents']),
            Icons.payments_outlined,
            const Color(0xFF2563EB),
          ),
          (
            'Lucro bruto',
            brl(summary['gross_profit_cents']),
            Icons.trending_up,
            const Color(0xFF16A34A),
          ),
          (
            'Margem',
            summary['margin_percent'] == null
                ? '—'
                : '${summary['margin_percent']}%',
            Icons.pie_chart_outline,
            const Color(0xFF7C3AED),
          ),
          (
            'Vendas',
            '${summary['sales_count']}',
            Icons.receipt_long_outlined,
            const Color(0xFFF59E0B),
          ),
        ];
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: sell,
                icon: const Icon(Icons.add),
                label: const Text('Registrar venda'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (_, box) {
                final w = box.maxWidth >= 760
                    ? (box.maxWidth - 48) / 4
                    : (box.maxWidth - 16) / 2;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: metrics
                      .map(
                        (m) => SizedBox(
                          width: w,
                          child: Metric(
                            title: m.$1,
                            value: m.$2,
                            icon: m.$3,
                            color: m.$4,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 22),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vendas recentes',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  if (transactions.isEmpty)
                    const Empty(text: 'Nenhuma venda registrada ainda.')
                  else
                    ...transactions
                        .take(5)
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(Icons.shopping_bag_outlined),
                            ),
                            title: Text(
                              item['description'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${item['margin_percent']}% de margem',
                            ),
                            trailing: Text(
                              brl(item['total_amount_cents']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        );
      }),
    ),
  );
}

class Stock extends StatelessWidget {
  const Stock({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: Api.get('/v1/products'),
    builder: (_, snapshot) => Frame(
      title: 'Estoque',
      subtitle: 'Acompanhe seus produtos e saiba o momento de repor.',
      child: state(
        snapshot,
        (data) => Panel(
          child: Column(
            children: (data as List).map((p) {
              final low = p['stock_quantity'] <= p['min_stock_quantity'];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: low
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: low
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF2563EB),
                  ),
                ),
                title: Text(
                  p['name'],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Venda ${brl(p['sale_price_cents'])}  •  Custo ${brl(p['cost_price_cents'])}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p['stock_quantity']} un.',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      low ? 'Estoque baixo' : 'Disponível',
                      style: TextStyle(
                        fontSize: 12,
                        color: low
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}

class Sale extends StatefulWidget {
  const Sale({super.key, required this.done});
  final VoidCallback done;
  @override
  State<Sale> createState() => _SaleState();
}

class _SaleState extends State<Sale> {
  final text = TextEditingController(
    text: 'vendi duas camisetas por cinquenta reais cada',
  );
  dynamic preview;
  bool busy = false;
  Future<void> interpret() async {
    setState(() => busy = true);
    try {
      final value = await Api.post('/v1/sales/preview', {'text': text.text});
      setState(() => preview = value);
    } catch (e) {
      message(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirm() async {
    setState(() => busy = true);
    try {
      await Api.post('/v1/sales/confirm', {
        'items': (preview['items'] as List)
            .map(
              (i) => {
                'product_id': i['product_id'],
                'quantity': i['quantity'],
                'unit_price_cents': i['unit_price_cents'],
              },
            )
            .toList(),
        'source': 'TEXT',
        'original_input': text.text,
        'idempotency_key': id(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Venda confirmada e estoque atualizado!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        widget.done();
      }
    } catch (e) {
      message(e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void message(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String id() {
    final x = DateTime.now().microsecondsSinceEpoch
        .toRadixString(16)
        .padLeft(12, '0');
    return '11111111-1111-4111-8111-${x.substring(x.length - 12)}';
  }

  @override
  Widget build(BuildContext context) => Frame(
    title: 'Registrar venda',
    subtitle: 'Conte o que vendeu do seu jeito. O ContAI organiza para você.',
    child: Column(
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O que aconteceu?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 7),
              const Text(
                'Exemplo: “Vendi duas camisetas por cinquenta reais cada.”',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: text,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Digite sua venda...',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : interpret,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        busy ? 'Interpretando...' : 'Interpretar venda',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () =>
                        message('Áudio será ativado com a chave da OpenAI.'),
                    icon: const Icon(Icons.mic_none),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (preview != null) ...[
          const SizedBox(height: 20),
          Preview(
            data: preview,
            confirm: busy ? null : confirm,
            edit: () => setState(() => preview = null),
          ),
        ],
      ],
    ),
  );
}

class Preview extends StatelessWidget {
  const Preview({
    super.key,
    required this.data,
    required this.confirm,
    required this.edit,
  });
  final dynamic data;
  final VoidCallback? confirm;
  final VoidCallback edit;
  @override
  Widget build(BuildContext context) {
    final item = data['items'][0];
    final values = [
      ('Produto', item['product_name']),
      ('Quantidade', '${item['quantity']} un.'),
      ('Faturamento', brl(data['total_amount_cents'])),
      ('Custo', brl(data['total_cost_cents'])),
      ('Lucro', brl(data['gross_profit_cents'])),
      ('Margem', '${data['margin_percent']}%'),
      ('Estoque', '${item['stock_before']} → ${item['stock_after']}'),
    ];
    return Panel(
      border: const Color(0xFFBFDBFE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✓ Confira antes de confirmar',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: values
                .map(
                  (v) => Container(
                    width: 155,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.$2,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: v.$1 == 'Lucro' || v.$1 == 'Margem'
                                ? const Color(0xFF16A34A)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          if ((data['warnings'] as List).isNotEmpty) ...[
            const SizedBox(height: 14),
            ...data['warnings'].map<Widget>(
              (w) => Text(
                '⚠ $w',
                style: const TextStyle(color: Color(0xFFF59E0B)),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: edit, child: const Text('Corrigir')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: confirm,
                icon: const Icon(Icons.check),
                label: const Text('Confirmar venda'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget state(AsyncSnapshot snapshot, Widget Function(dynamic) ready) =>
    snapshot.hasError
    ? ErrorBox(text: snapshot.error.toString())
    : snapshot.hasData
    ? ready(snapshot.data)
    : const Panel(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(25),
            child: CircularProgressIndicator(),
          ),
        ),
      );

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.border});
  final Widget child;
  final Color? border;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(21),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border ?? const Color(0xFFE7EEF8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x090F172A),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

class Metric extends StatelessWidget {
  const Metric({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: .1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(color: Color(0xFF64748B))),
        Text(
          value,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class ErrorBox extends StatelessWidget {
  const ErrorBox({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        const Icon(Icons.cloud_off, size: 40, color: Color(0xFFDC2626)),
        const SizedBox(height: 10),
        const Text(
          'Não foi possível acessar a API.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}

class Empty extends StatelessWidget {
  const Empty({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(25),
    child: Center(
      child: Text(text, style: const TextStyle(color: Color(0xFF64748B))),
    ),
  );
}

class About extends StatelessWidget {
  const About({super.key});
  @override
  Widget build(BuildContext context) => const Frame(
    title: 'Sobre o ContAI',
    subtitle: 'Menos tempo fazendo conta. Mais tempo vendendo.',
    child: Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seu copiloto financeiro',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 10),
          Text(
            'O ContAI transforma uma frase em venda, estoque e lucro, sempre mostrando uma prévia antes de registrar.',
          ),
          SizedBox(height: 20),
          Text(
            'Plano Solo • R\$ 14,90/mês',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Valores sujeitos à validação durante o piloto.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    ),
  );
}
