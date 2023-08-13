import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/screens/new_item_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<GroceryItem> _groceryItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      "firebase",
      "shopping-list.json",
    );
    try {
      final response = await http.get(url);

      if (response.statusCode >= 400) {
        setState(() {
          _error = "Failed to fetch the data.";
        });
      } else {
        _error = null;
        if (response.body == "null") {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        final Map<String, dynamic> data = json.decode(response.body);
        final List<GroceryItem> _loadedItems = [];
        for (final item in data.entries) {
          final category = categories.entries
              .firstWhere(
                  (catItem) => catItem.value.title == item.value["category"])
              .value;
          _loadedItems.add(
            GroceryItem(
              id: item.key,
              name: item.value["name"],
              quantity: item.value["quantity"],
              category: category,
            ),
          );
          setState(() {
            _groceryItems = _loadedItems;
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      setState(() {
        _error = "Something went wrong...";
      });
    }
  }

  void _addItem() async {
    final item = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItemScreen(),
      ),
    );
    setState(
      () {
        if (item != null) {
          _groceryItems.add(item);
        }
      },
    );
  }

  void _removeItem(int index) async {
    final tempGroceryItem = _groceryItems[index];
    setState(() {
      _groceryItems.removeAt(index);
    });
    final url = Uri.https(
      "firebase",
      "shopping-list/${tempGroceryItem.id}.json",
    );
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, tempGroceryItem);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Groceries",
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addItem,
          )
        ],
      ),
      body: SafeArea(
        child: _error == null
            ? _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _groceryItems.isEmpty
                    ? Center(
                        child: Text(
                          "No items added yet\n\nTry adding some",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _groceryItems.length,
                        itemBuilder: (BuildContext context, int index) =>
                            Dismissible(
                          key: ValueKey(_groceryItems[index].id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              _removeItem(index);
                            });
                          },
                          child: ListTile(
                            leading: Container(
                              width: 24,
                              height: 24,
                              color: _groceryItems[index].category.color,
                            ),
                            title: Text(_groceryItems[index].name),
                            trailing: Text(
                              _groceryItems[index].quantity.toString(),
                            ),
                          ),
                        ),
                      )
            : Center(
                child: Text(
                  _error!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge!
                      .copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}
