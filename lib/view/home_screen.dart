import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squire/view_models/home_view_model.dart';
import 'ArmyListLoaded.dart';
import 'package:squire/view/UnitDetailsScreen.dart';
import 'package:squire/data/model/Army_list/Army_unit_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  // Changed to nullable to safely check initialization state in dispose
  HomeViewModel? _model;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Assignment is slightly different since _model is now nullable
      _model = Provider.of<HomeViewModel>(context, listen: false);
      _model!.navigateToDetails.addListener(_handleNavigation);
    });
  }

  @override
  void dispose() {
    if (mounted) {
      // Added a correct null check
      if (_model != null) {
        _model!.navigateToDetails.removeListener(_handleNavigation);
      }
    }
    _textController.dispose();
    super.dispose();
  }

  void _handleNavigation() {
    final listPa = _model!.navigateToDetails.value;

    if (listPa != null) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              // PASS ListPa: Pass the structured ListPa object
              builder: (context) => ArmyListLoadedScreen(armyList: listPa),
            ),
          )
          .then((_) {
            _model!.navigateToDetails.value = null;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Army List Detail Viewer'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Input Area ---
            const Text(
              'Paste your Army List below:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _textController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText:
                    'Faction : STARK\nCommander : Robb Stark - The Wolf Lord\n...\nUnits :',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.grey[100],
                filled: true,
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. Action Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: model.isLoading
                    ? null
                    : () {
                        model.parseArmyList(_textController.text);
                      },
                icon: model.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  model.isLoading ? 'LOADING...' : 'PARSE & FETCH DETAILS',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const Divider(height: 32),

            // --- 3. Error Message Display ---
            if (model.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Error: ${model.errorMessage}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // --- 4. Parsed List Summary (if available) ---
            if (model.listPa != null) _buildArmySummary(context, model),

            const SizedBox(height: 24),

            if (model.listPa == null && !model.isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: Text(
                    'Paste an army list to begin.',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildArmySummary(BuildContext context, HomeViewModel model) {
    final list = model.listPa!;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Army Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Divider(),
            _buildSummaryRow('Faction:', list.faction),
            _buildSummaryRow('Commander:', list.commanderName),
            _buildSummaryRow('Points:', list.totalPoints.toString()),
            _buildSummaryRow('Activations:', list.totalActivations.toString()),
            const SizedBox(height: 10),
            // FIX: Use the list length directly, as combatUnits only contains CUs
            _buildUnitList('Combat Units:', list.combatUnits.length),
            _buildUnitList('Non-Combat Units (NCUs):', list.ncus.length),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUnitList(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            '$count units',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ],
      ),
    );
  }
}
