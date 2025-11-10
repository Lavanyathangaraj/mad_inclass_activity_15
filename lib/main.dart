import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORTANT: Ensure this import path is correct for your generated file
import 'package:ica15/firebase_options.dart'; 

// ====================================================================
// APP ENTRY POINT & FIREBASE INITIALIZATION
// ====================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(InventoryApp()); 
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App', // [cite: 184]
      theme: ThemeData(primarySwatch: Colors.blue), // [cite: 185]
      home: InventoryHomePage(title: 'Inventory Home Page'), // [cite: 186]
    );
  }
}

// ====================================================================
// STEP 1: DATA MODEL (Item Class)
// ====================================================================

class Item {
  final String? id; // (String, optional) [cite: 35]
  final String name; // (String) [cite: 35]
  final int quantity; // (int) [cite: 35]
  final double price; // (double) [cite: 35]
  final String category; // (String) [cite: 35]
  final DateTime createdAt; // (DateTime) [cite: 35]

  Item({
    this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    required this.createdAt,
  });

  // Convert Item object to Map for Firestore [cite: 36]
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'category': category,
      // Convert DateTime to Firestore Timestamp [cite: 38]
      'createdAt': Timestamp.fromDate(createdAt), 
    };
  }

  // Create Item from a Firestore snapshot [cite: 37]
  factory Item.fromMap(String id, Map<String, dynamic> map) {
    // Convert Firestore Timestamp back to DateTime [cite: 38]
    Timestamp timestamp = map['createdAt'] as Timestamp;

    return Item(
      id: id,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      price: map['price'] as double,
      category: map['category'] as String,
      createdAt: timestamp.toDate(),
    );
  }
}


// ====================================================================
// STEP 2: FIRESTORE SERVICE LAYER
// ====================================================================

class FirestoreService {
  final CollectionReference _itemsCollection =
      FirebaseFirestore.instance.collection('items'); // [cite: 63, 11]

  // Add (Create) operation [cite: 57]
  Future<void> addItem(Item item) async {
    await _itemsCollection.add(item.toMap()); // [cite: 11]
  }

  // Get Items Stream (Read) operation [cite: 58]
  Stream<List<Item>> getItemsStream() {
    return _itemsCollection.snapshots().map((snapshot) { // [cite: 11]
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Update operation [cite: 59]
  Future<void> updateItem(Item item) async {
    if (item.id == null) return; 
    await _itemsCollection.doc(item.id).update(item.toMap()); // [cite: 11]
  }

  // Delete operation [cite: 60]
  Future<void> deleteItem(String itemId) async {
    await _itemsCollection.doc(itemId).delete(); // [cite: 11]
  }
}

// ====================================================================
// STEP 3, 4, & ENHANCED FEATURE 1: UI IMPLEMENTATION (Home Screen & Filtering)
// ====================================================================

class InventoryHomePage extends StatefulWidget { // [cite: 190]
  InventoryHomePage({Key? key, required this.title}) : super(key: key); // [cite: 191]
  final String title;

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState(); // [cite: 194]
}

class _InventoryHomePageState extends State<InventoryHomePage> { // [cite: 196]
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedCategory; // State for category filter (Enhanced Feature 1)

  // Filter items based on the selected category
  List<Item> _filterItems(List<Item> items) {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return items;
    }
    return items.where((item) => item.category == _selectedCategory).toList();
  }

  // Extract unique categories for the dropdown
  List<String> _getUniqueCategories(List<Item> items) {
    Set<String> categories = items.map((item) => item.category).toSet();
    return ['All', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // [cite: 204]
        title: Text(widget.title),
        actions: [ // <-- FIX: actions parameter moved inside AppBar
          // Navigation button for Dashboard (Enhanced Feature 2)
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()), 
              );
            },
            tooltip: 'Dashboard',
          ),
        ],
      ),
      body: StreamBuilder<List<Item>>( // [cite: 82, 90]
        stream: _firestoreService.getItemsStream(), // [cite: 91]
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // [cite: 93]
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // [cite: 94]
          }
          
          final allItems = snapshot.data ?? [];
          final filteredItems = _filterItems(allItems);
          final categories = _getUniqueCategories(allItems);

          if (allItems.isEmpty) {
            return const Center(child: Text('No inventory items. Tap + to add one.')); // [cite: 95]
          }

          return Column(
            children: [
              // Category Filter Dropdown (Enhanced Feature 1)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: _selectedCategory ?? 'All',
                  isExpanded: true,
                  hint: const Text('Filter by Category'),
                  items: categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
              ),
              
              // Item List
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(child: Text('No items found for category: $_selectedCategory'))
                    : ListView.builder( // [cite: 96]
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text('Qty: ${item.quantity} | Price: \$${item.price.toStringAsFixed(2)}'),
                            trailing: Text(item.category),
                            onTap: () {
                              // Edit Navigation [cite: 137, 147-155]
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditItemScreen(item: item), 
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton( // [cite: 99]
        onPressed: () { // [cite: 100, 140-146]
          Navigator.push( 
            context,
            MaterialPageRoute(builder: (context) => AddEditItemScreen()),
          );
        },
        tooltip: 'Add Item',
        child: const Icon(Icons.add), // [cite: 103]
      ),
    );
  }
}

// ====================================================================
// ENHANCED FEATURE 2: DATA INSIGHTS DASHBOARD
// ====================================================================

class DashboardScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService(); // Removed const
  
  DashboardScreen({super.key}); // Removed const

  final int _lowStockThreshold = 10; // Define low stock threshold

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Dashboard')), 
      body: StreamBuilder<List<Item>>(
        stream: _firestoreService.getItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final items = snapshot.data ?? [];

          // --- Dashboard Calculations ---
          final totalUniqueItems = items.length; // [cite: 163]
          // Total value of all inventory (sum of quantity * price) [cite: 164]
          final totalValue = items.fold(0.0, (sum, item) => sum + (item.quantity * item.price)); 
          final lowStockItems = items.where((item) => item.quantity <= _lowStockThreshold).toList();
          final outOfStockItems = items.where((item) => item.quantity == 0).toList(); // [cite: 165]
          // -----------------------------

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Key Statistics Cards
              _buildStatCard(context, 'Total Unique Items', totalUniqueItems.toString(), Icons.layers),
              _buildStatCard(context, 'Total Inventory Value', '\$${totalValue.toStringAsFixed(2)}', Icons.monetization_on),
              _buildStatCard(context, 'Low Stock Items', lowStockItems.length.toString(), Icons.warning, color: lowStockItems.isNotEmpty ? Colors.orange : Colors.green),
              
              const SizedBox(height: 20),
              const Text('Out-of-Stock Items (Quantity = 0)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              
              // List of Out-of-Stock Items
              if (outOfStockItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('All items are in stock!', style: TextStyle(fontStyle: FontStyle.italic)),
                )
              else
                ...outOfStockItems.map((item) => ListTile(
                  leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  title: Text(item.name),
                  subtitle: Text('Category: ${item.category}'),
                )).toList(),
            ],
          );
        },
      ),
    );
  }

  // Helper widget for statistics display
  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, {Color color = Colors.blue}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// STEP 3 & 4: UI IMPLEMENTATION (Add/Edit Screen)
// ====================================================================

class AddEditItemScreen extends StatefulWidget {
  final Item? item; // [cite: 111]

  const AddEditItemScreen({super.key, this.item});

  @override
  _AddEditItemScreenState createState() => _AddEditItemScreenState(); // [cite: 113]
}

class _AddEditItemScreenState extends State<AddEditItemScreen> { // [cite: 115]
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService(); 

  bool get isEditing => widget.item != null; 

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      // Pre-fill fields for editing [cite: 137]
      _nameController.text = widget.item!.name;
      _quantityController.text = widget.item!.quantity.toString();
      _priceController.text = widget.item!.price.toString();
      _categoryController.text = widget.item!.category;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Handle Save (Create/Update)
  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final category = _categoryController.text;

      final newItem = Item(
        id: isEditing ? widget.item!.id : null, 
        name: name,
        quantity: quantity,
        price: price,
        category: category,
        createdAt: isEditing ? widget.item!.createdAt : DateTime.now(), 
      );

      if (isEditing) {
        await _firestoreService.updateItem(newItem); // Update item [cite: 137]
      } else {
        await _firestoreService.addItem(newItem); // Create item [cite: 135]
      }
      if (mounted) Navigator.pop(context);
    }
  }

  // Handle Delete [cite: 138]
  Future<void> _deleteItem() async {
    if (widget.item?.id != null) {
      await _firestoreService.deleteItem(widget.item!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // [cite: 118]
      appBar: AppBar(title: Text(isEditing ? 'Edit Item' : 'Add New Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form( // [cite: 119]
          key: _formKey,
          child: ListView( 
            children: [
              // TextFormField for name [cite: 122]
              TextFormField(
                controller: _nameController, 
                decoration: const InputDecoration(labelText: 'Name'), 
                validator: (v) => v!.isEmpty ? 'Enter item name' : null
              ),
              // TextFormField for quantity [cite: 123]
              TextFormField(
                controller: _quantityController, 
                decoration: const InputDecoration(labelText: 'Quantity'), 
                keyboardType: TextInputType.number, 
                validator: (v) => int.tryParse(v ?? '') == null ? 'Enter valid quantity' : null
              ),
              // TextFormField for price [cite: 124]
              TextFormField(
                controller: _priceController, 
                decoration: const InputDecoration(labelText: 'Price (\$)'), 
                keyboardType: TextInputType.number, 
                validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid price' : null
              ),
              // TextFormField for category [cite: 125]
              TextFormField(
                controller: _categoryController, 
                decoration: const InputDecoration(labelText: 'Category'), 
                validator: (v) => v!.isEmpty ? 'Enter category' : null
              ),

              const SizedBox(height: 30),

              // Save button [cite: 126]
              ElevatedButton(
                onPressed: _saveItem, 
                child: Text(isEditing ? 'Update Item' : 'Save New Item')
              ),

              // Delete button (only in edit mode) [cite: 127]
              if (isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: OutlinedButton(
                    onPressed: _deleteItem, 
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red), 
                    child: const Text('Delete Item')
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}