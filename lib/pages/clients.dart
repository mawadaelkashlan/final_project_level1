import 'package:final_project_level1/helpers/sql_helper.dart';
import 'package:final_project_level1/models/client.dart';
import 'package:final_project_level1/widgets/app_table.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'clients_ops.dart';

class Clients extends StatefulWidget {
  const Clients({super.key});

  @override
  State<Clients> createState() => _ClientsState();
}

class _ClientsState extends State<Clients> {
  List<ClientData>? clients;
  List<ClientData>? allClients;
  bool _sortNameAsc = true;

  int? _sortColumnIndex;

  bool _sortAsc = true;

  @override
  void initState() {
    getClients();
    super.initState();
  }

  void getClients() async {
    try {
      var sqlHelper = GetIt.I.get<SqlHelper>();
      var data = await sqlHelper.db!.query('clients');
      if (data.isNotEmpty) {
        clients = [];
        allClients = [];
        for (var item in data) {
          var client = ClientData.fromJson(item);
          clients!.add(client);
          allClients!.add(client);
        }
      } else {
        clients = [];
        allClients = [];
      }
    } catch (e) {
      print('Error In get clients data $e');
      clients = [];
      allClients = [];
    }
    setState(() {});
  }

  String selectedFilter = 'name';

  void searchClients(String query) {
    if (query.isEmpty) {
      clients = allClients;
    } else {
      clients = allClients!.where((client) {
        final clientValue = (selectedFilter == 'name'
            ? client.name
            : selectedFilter == 'email' ? client.email
            : client.phone)!.toLowerCase();
        final searchQuery = query.toLowerCase();

        return clientValue.contains(searchQuery);
      }).toList();
    }
    setState(() {});
  }

  final formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
              onPressed: () async {
                var result = await Navigator.push(context,
                    MaterialPageRoute(builder: (ctx) => ClientsOpsPage()));
                if (result ?? false) {
                  getClients();
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
                    onChanged: searchClients,
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
                  items: <String>['name', 'email' , 'phone']
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
                minWidth: 800,
                columns:  [
                  DataColumn(label: Text('Id'),
                      onSort: (columnIndex, sortAscending){
                        setState(() {
                          if (columnIndex == _sortColumnIndex) {
                            _sortAsc = _sortNameAsc = sortAscending;
                          } else {
                            _sortColumnIndex = columnIndex;
                            _sortAsc = _sortNameAsc;
                          }
                          clients!.sort((a, b) => a.name!.compareTo(b.name!));
                          if (!_sortAsc) {
                            clients = clients!.reversed.toList();
                          }
                        });
                      }),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Center(child: Text('Actions'))),
                ],
                source: ClientsTableSource(
                  categoriesEx: clients,
                  onUpdate: (clientData) async {
                    var result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (ctx) => ClientsOpsPage(
                              clientData: clientData,
                            )));
                    if (result ?? false) {
                      getClients();
                    }
                  },
                  onDelete: (clientData) {
                    onDeleteRow(clientData.id!);
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
              title: const Text('Delete Client'),
              content:
              const Text('Are you sure you want to delete this client?'),
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
          'clients',
          where: 'id =?',
          whereArgs: [id],
        );
        if (result > 0) {
          getClients();
        }
      }
    } catch (e) {
      print('Error In delete data $e');
    }
  }

  Future<void> onSubmit() async {
    try {
      if (formKey.currentState!.validate()) {
        var sqlHelper = GetIt.I.get<SqlHelper>();
        await sqlHelper.db!.insert('clients', {
          'name': nameController.text,
          'phone': phoneController.text,
          'email': emailController.text,
          'address': addressController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Colors.green,
            content: Text('client added Successfully')));
        Navigator.pop(context, true);
        getClients();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error In adding client : $e')));
    }
  }
}

class ClientsTableSource extends DataTableSource {
  List<ClientData>? categoriesEx;
  void Function(ClientData) onUpdate;
  void Function(ClientData) onDelete;

  ClientsTableSource({
    required this.categoriesEx,
    required this.onUpdate,
    required this.onDelete,
  });

  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  void _sort<T>(
      Comparable<T> Function(ClientData client) getField,
      int columnIndex,
      bool ascending,
      ) {
    categoriesEx!.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= categoriesEx!.length) return null;
    final client = categoriesEx![index];
    return DataRow(
      cells: [
        DataCell(Text('${client.id}')),
        DataCell(Text('${client.name}')),
        DataCell(Text('${client.phone}')),
        DataCell(Text('${client.email}')),
        DataCell(Text('${client.address}')),
        DataCell(Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                onUpdate(client);
              },
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () {
                onDelete(client);
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => categoriesEx!.length;

  @override
  int get selectedRowCount => 0;

  @override
  bool get sortAscending => _sortAscending;

  @override
  int get sortColumnIndex => _sortColumnIndex;

  @override
  void sort<T>(Comparable<T> Function(ClientData client) getField, bool ascending) {
    _sort(getField, 0, ascending);
  }
}