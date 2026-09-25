import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const PublicacionesApp());
}

class PublicacionesApp extends StatelessWidget {
  const PublicacionesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nueva publicación',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const NuevaPublicacionPage(),
    );
  }
}

class NuevaPublicacionPage extends StatefulWidget {
  const NuevaPublicacionPage({super.key});

  @override
  State<NuevaPublicacionPage> createState() => _NuevaPublicacionPageState();
}

class _NuevaPublicacionPageState extends State<NuevaPublicacionPage> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _autorController = TextEditingController(text: '1');

  bool _enviando = false;
  String? _mensaje;
  bool _exito = false;
  int? _idCreado;

  Future<void> _registrarPublicacion() async {
    if (!_formKey.currentState!.validate() || _enviando) return;

    setState(() {
      _enviando = true;
      _mensaje = null;
      _exito = false;
      _idCreado = null;
    });

    try {
      final respuesta = await http
          .post(
            Uri.parse('https://dummyjson.com/posts/add'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'title': _tituloController.text.trim(),
              'body': _contenidoController.text.trim(),
              'userId': int.parse(_autorController.text),
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
        final datos = jsonDecode(respuesta.body);

        setState(() {
          _exito = true;
          _idCreado = datos['id'];
          _mensaje = 'Publicación registrada correctamente.';
        });
      } else {
        setState(() {
          _mensaje = 'El servidor rechazó la solicitud '
              '(código ${respuesta.statusCode}).';
        });
      }
    } on http.ClientException {
      setState(() {
        _mensaje = 'No se pudo conectar con el servidor.';
      });
    } on FormatException {
      setState(() {
        _mensaje = 'El servidor devolvió una respuesta no válida.';
      });
    } catch (_) {
      setState(() {
        _mensaje = 'La solicitud no pudo completarse. '
            'Revisa tu conexión e inténtalo nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  void _limpiarFormulario() {
    _tituloController.clear();
    _contenidoController.clear();
    _autorController.text = '1';

    setState(() {
      _mensaje = null;
      _exito = false;
      _idCreado = null;
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _autorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva publicación'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El título es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _contenidoController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'El contenido es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _autorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Id del autor',
                  helperText: 'Un número entre 1 y 100',
                  border: OutlineInputBorder(),
                ),
                validator: (valor) {
                  final id = int.tryParse(valor ?? '');

                  if (id == null || id < 1 || id > 100) {
                    return 'Ingresa un número entre 1 y 100';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : _registrarPublicacion,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    _enviando
                        ? 'Registrando publicación...'
                        : 'Registrar publicación',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_mensaje != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          _mensaje!,
                          textAlign: TextAlign.center,
                        ),

                        if (_exito && _idCreado != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'El servidor asignó el identificador: $_idCreado',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _limpiarFormulario,
                            child: const Text('Limpiar formulario'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
