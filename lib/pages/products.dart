import 'package:data_table_2/data_table_2.dart';
import 'package:final_project_level1/pages/products_ops.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../helpers/sql_helper.dart';
import '../models/products.dart';
import '../widgets/app_table.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product>? products;
  List<Product>? allProducts;

  bool _sortNameAsc = true;

  int? _sortColumnIndex;

  bool _sortAsc = true;
  @override
  void initState() {
    getProducts();
    super.initState();
  }

  void getProducts() async {
    try {
      var sqlHelper = GetIt.I.get<SqlHelper>();
      var data = await sqlHelper.db!.rawQuery("""
      select P.* ,C.name as categoryName,C.description as categoryDesc 
      from products P
      inner join categories C
      where P.categoryId = C.id
      """);

      if (data.isNotEmpty) {
        products = [];
        allProducts = [];
        for (var item in data) {
          var product = Product.fromJson(item);
          products!.add(product);
          allProducts!.add(product);
        }
      } else {
        products = [];
        allProducts = [];
      }
    } catch (e) {
      print('Error In get data $e');
      products = [];
      allProducts = [];
    }
    setState(() {});
  }

  String selectedFilter = 'name';

  void searchProducts(String query) {
    if (query.isEmpty) {
      products = allProducts;
    } else {
      products = allProducts!.where((product) {
        final productValue = (selectedFilter == 'name'
            ? product.name
            : selectedFilter == 'description'
            ? product.description
            : product.price.toString())!
            .toLowerCase();
        final searchQuery = query.toLowerCase();

        return productValue.contains(searchQuery);
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
              onPressed: () async {
                var result = await Navigator.push(context,
                    MaterialPageRoute(builder: (ctx) => ProductOpsPage()));
                if (result ?? false) {
                  getProducts();
                }
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: searchProducts,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      labelText: 'Search',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedFilter,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                    });
                  },
                  items: <String>['name', 'description', 'price']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Expanded(
              child: AppTable(
                minWidth: 1300,
                columns:  [
                  DataColumn(label: Text('Id'), onSort: (columnIndex, sortAscending){
                    setState(() {
                      if (columnIndex == _sortColumnIndex) {
                        _sortAsc = _sortNameAsc = sortAscending;
                      } else {
                        _sortColumnIndex = columnIndex;
                        _sortAsc = _sortNameAsc;
                      }
                      products!.sort((a, b) => a.name!.compareTo(b.name!));
                      if (!_sortAsc) {
                        products = products!.reversed.toList();
                      }
                    });
                  }),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('isAvaliable')),
                  DataColumn(label: Center(child: Text('Image'))),
                  DataColumn(label: Text('Category ID')),
                  DataColumn(label: Text('Category Name')),
                  DataColumn(label: Text('Category Description')),
                  DataColumn(label: Center(child: Text('Actions'))),
                ],
                source: ProductsSource(
                  productsEx: products,
                  onUpdate: (productData) async {
                    var result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => ProductOpsPage(
                              product: productData,
                            )));
                    if (result ?? false) {
                      getProducts();
                    }
                  },
                  onDelete: (productData) {
                    onDeleteRow(productData.id!);
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> onDeleteRow(int id) async {
    try {
      var dialogResult = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Product'),
              content:
              const Text('Are you sure you want to delete this product?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text('Delete'),
                ),
              ],
            );
          });

      if (dialogResult ?? false) {
        var sqlHelper = GetIt.I.get<SqlHelper>();
        var result = await sqlHelper.db!.delete(
          'products',
          where: 'id =?',
          whereArgs: [id],
        );
        if (result > 0) {
          getProducts();
        }
      }
    } catch (e) {
      print('Error In delete data $e');
    }
  }
}

class ProductsSource extends DataTableSource {
  List<Product>? productsEx;

  void Function(Product) onUpdate;
  void Function(Product) onDelete;
  ProductsSource({
    required this.productsEx,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    return DataRow2(cells: [
      DataCell(Text('${productsEx?[index].id}')),
      DataCell(Text('${productsEx?[index].name}')),
      DataCell(Text('${productsEx?[index].description}')),
      DataCell(Text('${productsEx?[index].price}')),
      DataCell(Text('${productsEx?[index].stock}')),
      DataCell(Text('${productsEx?[index].isAvaliable}')),
      DataCell(Center(
        child: Image.network(
          '${productsEx?[index].image}',
          fit: BoxFit.contain,
        ),
      )),
      DataCell(Text('${productsEx?[index].categoryId}')),
      DataCell(Text('${productsEx?[index].categoryName}')),
      DataCell(Text('${productsEx?[index].categoryDesc}')),
      DataCell(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              onUpdate(productsEx![index]);
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            onPressed: () {
              onDelete(productsEx![index]);
            },
            icon: const Icon(
              Icons.delete,
              color: Colors.red,
            ),
          ),
        ],
      )),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => productsEx?.length ?? 0;

  @override
  int get selectedRowCount => 0;
}