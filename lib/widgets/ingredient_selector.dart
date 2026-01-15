import 'package:flutter/material.dart';
import 'package:pick_my_dish/Services/api_service.dart';

class IngredientSelector extends StatefulWidget {
  final List<int> selectedIds;
  final Function(List<int>) onSelectionChanged;
  final String? hintText;
  final TextStyle? hintStyle;
  final bool allowAddingNew; // <-- ADD THIS
  final Future<List<Map<String, dynamic>>> Function()? ingredientLoader;
  
  const IngredientSelector({
    super.key,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.hintText = "Select ingredients",
    this.hintStyle,
    this.allowAddingNew = true, // <-- Default to true for upload screen
    this.ingredientLoader,
  });

  @override
  State<IngredientSelector> createState() => _IngredientSelectorState();
}

class _IngredientSelectorState extends State<IngredientSelector> {
  List<Map<String, dynamic>> _allIngredients = [];
  List<Map<String, dynamic>> _filteredIngredients = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newIngredientController = TextEditingController();
  bool _showAddIngredient = false;

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final loader = widget.ingredientLoader ?? ApiService.getIngredients;
      final ingredients = await loader();
      setState(() {
        _allIngredients = ingredients;
        _filteredIngredients = ingredients;
      });
    } catch (e) {
      debugPrint('Error loading ingredients: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newIngredientController.dispose();
    super.dispose();
  }

  void _filterIngredients(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredIngredients = _allIngredients;
      } else {
        _filteredIngredients = _allIngredients.where((ingredient) {
          final name = ingredient['name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _toggleIngredient(int ingredientId) {
    final newSelectedIds = List<int>.from(widget.selectedIds);
    
    if (newSelectedIds.contains(ingredientId)) {
      newSelectedIds.remove(ingredientId);
    } else {
      newSelectedIds.add(ingredientId);
    }
    
    widget.onSelectionChanged(newSelectedIds);
  }

  Future<void> _addNewIngredient() async {
    final name = _newIngredientController.text.trim();
    if (name.isEmpty) return;
    
    final success = await ApiService.addIngredient(name);
    if (success && mounted) {
      await _loadIngredients();
      _newIngredientController.clear();
      setState(() {
        _showAddIngredient = false;
      });
    }
  }

  String _getIngredientName(int id) {
    final ingredient = _allIngredients.firstWhere(
      (ing) => ing['id'] == id,
      orElse: () => {'name': 'Unknown'},
    );
    return ingredient['name'];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: _filterIngredients,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: widget.hintStyle ?? const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.orange),
                      onPressed: () {
                        _searchController.clear();
                        _filterIngredients('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // Selected ingredients chips
        if (widget.selectedIds.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.selectedIds.map((id) {
              return Chip(
                label: Text(_getIngredientName(id)),
                onDeleted: () => _toggleIngredient(id),
                backgroundColor: Colors.orange.withValues(alpha: 0.2),
                deleteIconColor: Colors.orange,
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
        ],
        
        // Add new ingredient option - ONLY SHOW IF ALLOWED
        if (widget.allowAddingNew && _showAddIngredient) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newIngredientController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter new ingredient',
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: _addNewIngredient,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  setState(() => _showAddIngredient = false);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        
        // Ingredient list
        Container(
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListView.builder(
            itemCount: _filteredIngredients.length,
            itemBuilder: (context, index) {
              final ingredient = _filteredIngredients[index];
              final isSelected = widget.selectedIds.contains(ingredient['id']);
              return CheckboxListTile(
                title: Text(
                  ingredient['name'],
                  style: const TextStyle(color: Colors.orange),
                ),
                value: isSelected,
                onChanged: (_) => _toggleIngredient(ingredient['id']),
                activeColor: Colors.orange,
              );
            },
          ),
        ),
        
        // Add new ingredient button - ONLY SHOW IF ALLOWED
        if (widget.allowAddingNew && 
            !_showAddIngredient && 
            _searchController.text.isNotEmpty && 
            _filteredIngredients.isEmpty)
          TextButton.icon(
            icon: const Icon(Icons.add, color: Colors.orange),
            label: Text(
              'Add "${_searchController.text}" as new ingredient',
              style: const TextStyle(color: Colors.orange),
            ),
            onPressed: () {
              setState(() => _showAddIngredient = true);
              _newIngredientController.text = _searchController.text;
            },
          ),
      ],
    );
  }
}