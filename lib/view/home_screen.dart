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

  // --- Theme Colors ---
  final Color _scaffoldBackground = const Color(0xFF121212); // Deep dark gray
  final Color _cardBackground = const Color(
    0xFF1F1F1F,
  ); // Slightly lighter for contrast
  final Color _textFieldFill = const Color(
    0xFF2C2C2C,
  ); // Dark gray for input fields
  final Color _primaryText = Colors.white;
  final Color _secondaryText = Colors.white70;
  final Color _accentColor =
      Colors.grey.shade400; // Bright accent for highlights

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _model = Provider.of<HomeViewModel>(context, listen: false);
      _model!.navigateToDetails.addListener(_handleNavigation);
    });
  }

  @override
  void dispose() {
    if (mounted) {
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
      backgroundColor: _scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Squire',
          style: TextStyle(
            fontFamily: 'Tuff', // Applied custom font
            fontSize: 24,
          ),
        ),
        // Overriding the previous color settings for a darker look
        backgroundColor: _cardBackground,
        foregroundColor: _primaryText,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Input Area Title ---
            Text(
              'Paste your Army List below:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tuff', // Applied custom font
                color: _primaryText,
              ),
            ),
            const SizedBox(height: 12),

            // --- 2. Input Field ---
            TextFormField(
              controller: _textController,
              maxLines: 10,
              style: TextStyle(
                color: _primaryText,
                fontFamily: 'Garamond',
              ), // Applied Garamond for body text
              decoration: InputDecoration(
                hintText:
                    'Faction : STARK\nCommander : Robb Stark - The Wolf Lord\n...\nUnits :',
                hintStyle: TextStyle(
                  color: _secondaryText.withOpacity(0.5),
                  fontFamily: 'Garamond',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                fillColor: _textFieldFill,
                filled: true,
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. Action Button ---
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
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  model.isLoading ? 'LOADING...' : 'PARSE & FETCH DETAILS',
                  style: const TextStyle(
                    fontFamily: 'Tuff', // Applied custom font
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  // Dark theme button styling
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const Divider(height: 48, color: Colors.white10),

            // --- 4. Error Message Display ---
            if (model.errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Error: ${model.errorMessage}',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // --- 5. Parsed List Summary (if available) ---
            if (model.listPa != null) _buildArmySummary(context, model),

            const SizedBox(height: 24),

            if (model.listPa == null &&
                !model.isLoading &&
                model.errorMessage.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: Text(
                    'Paste an army list to begin.',
                    style: TextStyle(
                      fontSize: 18,
                      color: _secondaryText,
                      fontFamily: 'Garamond', // Applied Garamond font
                    ),
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
      color: _cardBackground, // Dark theme background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Army Summary',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tuff', // Applied custom font
                color: _accentColor,
              ),
            ),
            const Divider(color: Colors.white10),
            _buildSummaryRow('Faction:', list.faction),
            _buildSummaryRow('Commander:', list.commanderName),
            _buildSummaryRow('Points:', list.totalPoints.toString()),
            _buildSummaryRow('Activations:', list.totalActivations.toString()),
            const SizedBox(height: 10),
            _buildUnitList('Combat Units:', list.combatUnits.length),
            _buildUnitList('Non-Combat Units (NCUs):', list.ncus.length),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: _secondaryText,
              fontFamily: 'Garamond', // Applied Garamond font
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _primaryText,
              fontFamily: 'Tuff', // Applied Tuff font for emphasis
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitList(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: _secondaryText,
              fontFamily: 'Garamond', // Applied Garamond font
            ),
          ),
          Text(
            '$count units',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _accentColor,
              fontFamily: 'Tuff', // Applied Tuff font for emphasis
            ),
          ),
        ],
      ),
    );
  }
}
