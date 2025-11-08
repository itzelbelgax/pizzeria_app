import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

class PedidoPage extends StatefulWidget {
  @override
  _PedidoPageState createState() => _PedidoPageState();
}

class _PedidoPageState extends State<PedidoPage> {
  List<Map<String, dynamic>> menu = [
    {
      'nombre': 'Pizza Grande',
      'precio': 150,
      'ingredientesDisponibles': ['Queso extra', 'Pepperoni', 'Champiñones', 'Jalapeños']
    },
    {
      'nombre': 'Pizza Mediana',
      'precio': 120,
      'ingredientesDisponibles': ['Queso extra', 'Pepperoni', 'Champiñones', 'Jalapeños']
    },
    {
      'nombre': 'Pizza Chica',
      'precio': 90,
      'ingredientesDisponibles': ['Queso extra', 'Pepperoni', 'Champiñones', 'Jalapeños']
    },
    {'nombre': 'Refresco 600ml', 'precio': 25},
    {'nombre': 'Agua 500ml', 'precio': 20},
  ];

  // Pedido con cantidad e ingredientes seleccionados
  List<Map<String, dynamic>> pedido = [];

  // Mostrar diálogo para seleccionar ingredientes (solo pizzas)
  Future<List<String>?> _seleccionarIngredientes(List<String> ingredientesDisponibles) async {
    List<String> seleccionados = [];
    return showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecciona ingredientes'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ingredientesDisponibles.map((ingrediente) {
                    final seleccionado = seleccionados.contains(ingrediente);
                    return CheckboxListTile(
                      title: Text(ingrediente),
                      value: seleccionado,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            seleccionados.add(ingrediente);
                          } else {
                            seleccionados.remove(ingrediente);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context, null),
            ),
            ElevatedButton(
              child: Text('Agregar'),
              onPressed: () => Navigator.pop(context, seleccionados),
            ),
          ],
        );
      },
    );
  }

  // Agregar producto al pedido
  void agregarProducto(Map<String, dynamic> producto, {List<String>? ingredientes}) {
    setState(() {
      // Buscar producto igual (mismo nombre e ingredientes)
      int index = pedido.indexWhere((item) {
        if (item['nombre'] != producto['nombre']) return false;
        List<String> ingr1 = item['ingredientes']?.cast<String>() ?? [];
        List<String> ingr2 = ingredientes ?? [];
        return ListEquality().equals(ingr1, ingr2);
      });

      if (index >= 0) {
        // Sumar cantidad
        // Asegurarse que cantidad no sea null
        final currentCantidad = pedido[index]['cantidad'];
        pedido[index]['cantidad'] = (currentCantidad is int) ? currentCantidad + 1 : 1;
      } else {
        // Agregar nuevo con valores seguros
        pedido.add({
          'nombre': producto['nombre'],
          'precio': producto['precio'] ?? 0,
          'cantidad': 1,
          if (ingredientes != null) 'ingredientes': ingredientes,
        });
      }
    });
  }

  // Reducir cantidad o borrar producto
  void reducirOEliminarProducto(int index) {
    setState(() {
      final currentCantidad = pedido[index]['cantidad'];
      if (currentCantidad is int && currentCantidad > 1) {
        pedido[index]['cantidad'] = currentCantidad - 1;
      } else {
        pedido.removeAt(index);
      }
    });
  }

  double calcularTotal() {
    return pedido.fold(0, (sum, item) {
      final precio = item['precio'] ?? 0;
      final cantidad = item['cantidad'] ?? 0;
      if (precio is num && cantidad is num) {
        return sum + (precio * cantidad);
      }
      return sum;
    });
  }

  Future<void> guardarPedidoEnFirebase() async {
    if (pedido.isEmpty) return;

    Map<String, dynamic> productosCantidad = {};

    for (var item in pedido) {
      String key = item['nombre'];
      if (item['ingredientes'] != null && (item['ingredientes'] as List).isNotEmpty) {
        key += ' con ' + (item['ingredientes'] as List).join(', ');
      }
      productosCantidad[key] = item['cantidad'] ?? 0;
    }

    List<Map<String, dynamic>> productos = productosCantidad.entries
        .map((e) => {'nombre': e.key, 'cantidad': e.value})
        .toList();

    final nuevoPedido = {
      'productos': productos,
      'total': calcularTotal(),
      'fecha': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('pedidos').add(nuevoPedido);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido guardado en Firebase!')),
      );
      setState(() {
        pedido.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar pedido: $e')),
      );
    }
  }

  void confirmarPedido() {
    guardarPedidoEnFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Levantar Pedido')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final item = menu[index];
                return ListTile(
                  title: Text(item['nombre']),
                  subtitle: Text('\$${item['precio']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () async {
                      print('Presionaste agregar producto: ${item['nombre']}');

                        if (item.containsKey('ingredientesDisponibles')) {
                          print('La clave ingredientesDisponibles existe');
                          print('Ingredientes disponibles: ${item['ingredientesDisponibles']}');

                          final ingredientes = await _seleccionarIngredientes(item['ingredientesDisponibles']);

                          print('Ingredientes seleccionados: $ingredientes');

                          if (ingredientes != null) {
                            agregarProducto(item, ingredientes: ingredientes);
                          }
                        } else {
                          print('No hay ingredientes disponibles para este producto');
                          agregarProducto(item);
                        }
                    },
                  ),
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text('Pedido Actual:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...pedido.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final ingredientes = (item['ingredientes'] as List?)?.join(', ') ?? '';
                    return ListTile(
                      title: Text('${item['nombre']}${ingredientes.isNotEmpty ? ' ($ingredientes)' : ''}'),
                      subtitle: Text('Cantidad: ${item['cantidad']}  Precio unitario: \$${item['precio']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => reducirOEliminarProducto(index),
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
                Text('Total: \$${calcularTotal()}'),
                SizedBox(height: 8),
                ElevatedButton(
                  child: Text('Confirmar Pedido'),
                  onPressed: pedido.isEmpty ? null : confirmarPedido,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// Para comparar listas de ingredientes
