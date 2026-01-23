// import 'package:billcare/Products/addproductpage.dart';
import 'package:flutter/material.dart';

class AddUnitPage extends StatefulWidget {
  const AddUnitPage({super.key});

  @override
  _AddUnitPageState createState() => _AddUnitPageState();
}

class _AddUnitPageState extends State<AddUnitPage> {
  String? _fromUnit;
  String? _toUnit;
  final TextEditingController _conversionController = TextEditingController();

  final List<String> units = [
    'CARTONS ( Ctn )',
    'KILOGRAMS ( Kg )',
    'LITERS',
    'PCS',
  ];

  bool get _showConversion => _fromUnit != null && _toUnit != null;
  @override
  void initState() {
    super.initState();
    _conversionController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add Item Unit",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orangeAccent,
        leading: const BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "From Unit",
                    border: OutlineInputBorder(),
                  ),
                  value: _fromUnit,
                  items: units
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _fromUnit = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "To Unit",
                    border: OutlineInputBorder(),
                  ),
                  value: _toUnit,
                  items: units
                      .map(
                        (unit) =>
                            DropdownMenuItem(value: unit, child: Text(unit)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _toUnit = value),
                ),
                const SizedBox(height: 24),
                if (_showConversion) ...[
                  const Text(
                    "Select Conversion Rate",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        size: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Text("1 ${_fromUnit!.split(' ').first} = "),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          controller: _conversionController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_toUnit!.split(' ').first),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade800,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _showConversion && _conversionController.text.isNotEmpty
                      ? () {
                          // Build full unit string to pass: e.g., "1 CTN = 3.0 KG"
                          final from = _fromUnit!.split(' ').first;
                          final to = _toUnit!.split(' ').first;
                          final value = _conversionController.text.trim();
                          final unitString = "1 $from = $value $to";
                          Navigator.pop(context, unitString);
                        }
                      : null,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
