// lib/rutinas_pantalla.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- agregado

// ------------------- Rutinas -------------------
class RutinasPantalla extends StatefulWidget {
  final Map<String, dynamic> usuario; // perfil que se está viendo
  final bool esTutor; // quien está usando la app

  const RutinasPantalla(
      {super.key, required this.usuario, required this.esTutor});

  @override
  _RutinasPantallaState createState() => _RutinasPantallaState();
}

class _RutinasPantallaState extends State<RutinasPantalla> {
  final FlutterTts flutterTts = FlutterTts();
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // <-- instancia Firestore

  // Variables de refuerzo visual
  bool _mostrarEstrella = false;
  bool _mostrarCopa = false;
  DateTime? _lastFinalConfettiDate;

  // Timer para recordatorios
  Timer? _recordatorioTimer;

  // Confetti controllers
  late ConfettiController _confettiController;
  late ConfettiController _confettiFinalController;

  final List<String> pictogramas = [
    'desayuno.png',
    'mochila.png',
    'almuerzo.png',
    'juego.png',
    'bano.png',
    'usuario.png',
    'usuario2.png',
    'ejemplo.png',
    'dormir.png',
    'correr.png',
    'correr2.png',
    'ducharse.png',
  ];

  // ------------------- Rutinas predeterminadas -------------------
  // Nota: estas definiciones se usan como plantilla para garantizar persistencia
  final List<Map<String, dynamic>> _plantillaPredeterminadas = [
    {
      'nombre': 'Bañarse',
      'imagen': 'assets/images/ducharse.png',
      'hora': '07:30',
      'textoAudio': '¡Es hora de bañarse!',
      'completada': false,
      'repetir': true,
      'modoSecuencia': true,
      'pasos': [
        'Abrir la ducha',
        'Mojarse el cuerpo',
        'Usar jabón y enjuagar',
        'Secarse con la toalla',
      ],
    },
    {
      'nombre': 'Vestirse',
      'imagen': 'assets/images/vestir.png',
      'hora': '08:00',
      'textoAudio': '¡Hora de vestirse!',
      'completada': false,
      'repetir': true,
      'modoSecuencia': true,
      'pasos': [
        'Ponerse la camiseta',
        'Ponerse el pantalón',
        'Colocarse los calcetines',
        'Ponerse los zapatos',
      ],
    },
    {
      'nombre': 'Ir al colegio',
      'imagen': 'assets/images/colegio.png',
      'hora': '08:15',
      'textoAudio': '¡Hora de ir al colegio!',
      'completada': false,
      'repetir': true,
      'modoSecuencia': true,
      'pasos': [
        'Preparar la mochila',
        'Peinarse bien',
        'Ponerse los zapatos',
        'Salir rumbo al colegio',
      ],
    },
  ];

  // Lista que se usa en la UI (predeterminadas + rutinas creadas)
  List<Map<String, dynamic>> rutinas = [];

  // ------------------- AUDIO -------------------
  Future<void> _reproducirAudio(String texto) async {
    try {
      await flutterTts.setLanguage("es-ES");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.9);
      await flutterTts.setVolume(1.0);
      await flutterTts.speak(texto);
    } catch (e) {
      // noop
    }
  }

  // ------------------- INIT / DISPOSE -------------------
  @override
  void initState() {
    super.initState();

    // Inicializar flags para las plantillas locales (si se usan temporales)
    for (var r in _plantillaPredeterminadas) {
      r['mostrada'] = r.containsKey('mostrada') ? r['mostrada'] : false;
      r['completada'] = r.containsKey('completada') ? r['completada'] : false;
    }

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiFinalController =
        ConfettiController(duration: const Duration(seconds: 4));
    _lastFinalConfettiDate = null;

    // Cargar rutinas desde Firebase (esto también garantizará que las predeterminadas existan)
    _cargarRutinasFirebase();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _confettiFinalController.dispose();
    _recordatorioTimer?.cancel();
    super.dispose();
  }

  // ------------------- Cargar rutinas desde Firebase -------------------
  /// Este método:
  /// - Trae todas las rutinas del usuario desde Firestore.
  /// - Si faltan las rutinas predeterminadas ("Bañarse","Vestirse","Ir al colegio")
  ///   las crea en Firestore (para que persistan) y las añade al listado.
  /// - Finalmente deja en `rutinas` la lista: [predeterminadas (de firebase) en orden,
  ///   luego rutinas adicionales].
  Future<void> _cargarRutinasFirebase() async {
    try {
      final nombreUsuario = widget.usuario['nombre'];
      final snapshot = await _firestore
          .collection('rutinas')
          .where('usuario', isEqualTo: nombreUsuario)
          .get();

      // Map de rutinas ya en Firebase por nombre para fácil búsqueda
      final Map<String, Map<String, dynamic>> desdeFirebasePorNombre = {};

      for (var doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['idFirebase'] = doc.id;
        // asegurar flags
        data['mostrada'] =
            data.containsKey('mostrada') ? data['mostrada'] : false;
        data['completada'] =
            data.containsKey('completada') ? data['completada'] : false;
        desdeFirebasePorNombre[data['nombre']] = data;
      }

      // Lista final: recorrer las plantillas en orden y usar versión de firebase si existe
      final List<Map<String, dynamic>> listaFinal = [];

      for (var plantilla in _plantillaPredeterminadas) {
        final nombre = plantilla['nombre'];
        if (desdeFirebasePorNombre.containsKey(nombre)) {
          listaFinal.add(desdeFirebasePorNombre.remove(nombre)!);
        } else {
          // No existe en firebase: crearla y obtener su id
          final nueva = Map<String, dynamic>.from(plantilla);
          nueva['usuario'] = nombreUsuario;
          nueva['mostrada'] = false;
          nueva['completada'] = nueva['completada'] ?? false;
          final docRef = await _firestore.collection('rutinas').add(nueva);
          nueva['idFirebase'] = docRef.id;
          listaFinal.add(nueva);
        }
      }

      // Agregar las rutinas restantes que no son predeterminadas
      for (var remaining in desdeFirebasePorNombre.values) {
        listaFinal.add(remaining);
      }

      // Actualizar estado y (re)programar recordatorios
      setState(() {
        rutinas = listaFinal;
      });

      // arrancar programador con las horas cargadas
      _programarRecordatorios();
    } catch (e) {
      // noop (no interrumpimos la app)
    }
  }

  // ------------------- Refuerzo visual -------------------
  Widget _refuerzoVisual() {
    if (_mostrarEstrella) {
      return Center(
        child: Image.asset(
          'assets/images/premios/estrella.png',
          width: 175,
          height: 175,
        ),
      );
    } else if (_mostrarCopa) {
      return Center(
        child: Image.asset(
          'assets/images/premios/copa.png',
          width: 380,
          height: 380,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ------------------- Confeti / Recompensas -------------------
  void _mostrarConfeti() {
    try {
      _confettiController.play();
      flutterTts.speak("Muy bien");
      setState(() {
        _mostrarEstrella = true;
      });
      Future.delayed(const Duration(seconds: 5), () {
        setState(() {
          _mostrarEstrella = false;
        });
      });
    } catch (e) {}
  }

  Future<void> _mostrarConfetiFinalDia() async {
    try {
      final nowDT = DateTime.now();
      if (_lastFinalConfettiDate != null &&
          nowDT.difference(_lastFinalConfettiDate!).inSeconds < 5) return;

      setState(() {
        _mostrarCopa = true;
      });
      Future.delayed(const Duration(seconds: 10), () {
        setState(() {
          _mostrarCopa = false;
        });
      });

      _confettiFinalController.play();
      _lastFinalConfettiDate = nowDT;
      await flutterTts
          .speak("¡Felicidades! Has completado todas las rutinas del día.");
    } catch (e) {}
  }

  // ------------------- Mostrar Recordatorio ----------------------
  void _mostrarRecordatorio(Map<String, dynamic> rutina) {
    final index = rutinas.indexOf(rutina);

    _reproducirAudio(rutina['textoAudio']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.orangeAccent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          height: 400,
          color: Colors.orangeAccent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¡Hora de ${rutina['nombre']}!',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Image.asset(
                  rutina['imagen'],
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: const Text(
                'Tarea realizada',
                style: TextStyle(color: Colors.orangeAccent),
              ),
              onPressed: () async {
                setState(() {
                  rutinas[index]['completada'] = true;
                });

                // Persistir el cambio en Firestore (si aplica)
                await _guardarRutinaFirebase(rutinas[index]);

                _mostrarConfeti(); // Confeti + estrella
                if (rutinas.every((r) => r['completada'] == true)) {
                  _mostrarConfetiFinalDia(); // Doble confeti + copa
                }
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- Programar Recordatorios -------------------
  void _programarRecordatorios() {
    // Cancelar cualquier timer previo
    _recordatorioTimer?.cancel();

    // Revisar cada 10 segundos (puedes cambiar la duración)
    _recordatorioTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final ahora = TimeOfDay.now();

      for (var r in rutinas) {
        try {
          if (r['completada'] == false && r['mostrada'] == false) {
            // Convertir la hora de la rutina a TimeOfDay (almacenas como String HH:mm)
            final parts = (r['hora'] ?? '').toString().split(':');
            if (parts.length < 2) continue;
            final horaRutina = TimeOfDay(
                hour: int.parse(parts[0]), minute: int.parse(parts[1]));

            // Comparar con la hora actual
            if (horaRutina.hour == ahora.hour &&
                horaRutina.minute == ahora.minute) {
              // Mostrar recordatorio solo una vez
              r['mostrada'] = true;
              _mostrarRecordatorio(r);
              break; // mostrar un recordatorio a la vez
            }
          }
        } catch (e) {
          // ignore parse errors
        }
      }
    });
  }

  // ------------------- Selección de pictograma -------------------
  Future<String?> _seleccionarPictograma(String imagenActual) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Selecciona un pictograma'),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          body: Container(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: pictogramas.length,
              itemBuilder: (context, index) {
                final img = pictogramas[index];
                final path = 'assets/images/pictogramas/$img';
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, path);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.asset(
                        path,
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ------------------- Guardar rutina en Firebase -------------------
  Future<void> _guardarRutinaFirebase(Map<String, dynamic> rutina) async {
    try {
      // Preparamos la copia que guardaremos (sin campos temporales de UI)
      final dataGuardar = Map<String, dynamic>.from(rutina);
      dataGuardar.remove('ejecutando');

      // Asegurarnos que el campo 'usuario' esté presente
      dataGuardar['usuario'] = widget.usuario['nombre'];

      if (rutina.containsKey('idFirebase') && rutina['idFirebase'] != null) {
        // Actualizar documento existente
        await _firestore
            .collection('rutinas')
            .doc(rutina['idFirebase'])
            .set(dataGuardar, SetOptions(merge: true));
      } else {
        // Crear nuevo documento
        final docRef = await _firestore.collection('rutinas').add(dataGuardar);
        rutina['idFirebase'] = docRef.id;
      }

      // (Re)programar recordatorios por si la hora cambió
      _programarRecordatorios();
    } catch (e) {
      // Mostrar error suave al usuario
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al guardar la rutina en Firebase')),
        );
      } catch (_) {}
    }
  }

  // ------------------- Editar rutina -------------------
  void _editarRutina(Map<String, dynamic> rutina) {
    // Abrimos un diálogo similar a _agregarRutina pero inicializado con los valores actuales
    final nombreCtrl = TextEditingController(text: rutina['nombre'] ?? '');
    final horaParts = (rutina['hora'] ?? '08:00').toString().split(':');
    final horaCtrl =
        TextEditingController(text: horaParts.isNotEmpty ? horaParts[0] : '08');
    final minutoCtrl =
        TextEditingController(text: horaParts.length > 1 ? horaParts[1] : '00');
    String imagenSeleccionada =
        rutina['imagen'] ?? 'assets/images/pictogramas/desayuno.png';
    bool esSecuencia = rutina['modoSecuencia'] == true;
    List<TextEditingController> pasosCtrl = List.generate(4, (i) {
      if (rutina['pasos'] != null && (rutina['pasos'] as List).length > i) {
        return TextEditingController(
            text: (rutina['pasos'] as List)[i]?.toString() ?? '');
      } else {
        return TextEditingController();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Editar Rutina"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    hintText: "Nombre de la rutina",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: horaCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        decoration: const InputDecoration(
                          hintText: "HH",
                          border: OutlineInputBorder(),
                          counterText: "",
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Text(":", style: TextStyle(fontSize: 20)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: minutoCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        decoration: const InputDecoration(
                          hintText: "MM",
                          border: OutlineInputBorder(),
                          counterText: "",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (imagenSeleccionada.isNotEmpty)
                  Image.asset(imagenSeleccionada, width: 80, height: 80),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () async {
                    final resultado =
                        await _seleccionarPictograma(imagenSeleccionada);
                    if (resultado != null) {
                      setDialogState(() {
                        imagenSeleccionada = resultado;
                      });
                    }
                  },
                  child: const Text("Icono o Imagen"),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Modo Secuencia"),
                  value: esSecuencia,
                  onChanged: (v) {
                    setDialogState(() {
                      esSecuencia = v;
                    });
                  },
                ),
                if (esSecuencia)
                  Column(
                    children: List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextField(
                          controller: pasosCtrl[i],
                          decoration: InputDecoration(
                            hintText: 'Paso ${i + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final hora = int.tryParse(horaCtrl.text);
                final minuto = int.tryParse(minutoCtrl.text);
                if (nombreCtrl.text.isNotEmpty &&
                    hora != null &&
                    hora >= 0 &&
                    hora <= 23 &&
                    minuto != null &&
                    minuto >= 0 &&
                    minuto <= 59) {
                  final secuencia = esSecuencia
                      ? pasosCtrl
                          .map((e) => e.text.trim())
                          .where((t) => t.isNotEmpty)
                          .toList()
                      : [];

                  // Actualizar la rutina existente en memoria
                  setState(() {
                    rutina['nombre'] = nombreCtrl.text;
                    rutina['imagen'] = imagenSeleccionada;
                    rutina['hora'] =
                        '${horaCtrl.text.padLeft(2, '0')}:${minutoCtrl.text.padLeft(2, '0')}';
                    rutina['textoAudio'] = '¡Hora de ${nombreCtrl.text}!';
                    rutina['modoSecuencia'] = esSecuencia;
                    rutina['pasos'] = secuencia;
                    rutina['mostrada'] =
                        false; // permitir re-notificación si se modifica la hora
                  });

                  // Persistir cambios en Firebase
                  await _guardarRutinaFirebase(rutina);

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Ingresa una hora válida (HH:MM)")),
                  );
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- Crear tarjeta de rutina -------------------
  Widget _crearTarjetaRutina(Map<String, dynamic> rutina, int index) {
    return InkWell(
      onTap: () {
        // Evitar múltiples ejecuciones
        if (rutina['ejecutando'] == true) return;

        setState(() {
          rutina['ejecutando'] = true; // marca que la rutina se está ejecutando
        });

        // Reproducir audio de hora de rutina
        _reproducirAudio("¡Hora de ${rutina['nombre']}!");

        // Mostrar pantalla del pictograma con botón "Realizar tarea"
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.blueAccent.shade200,
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Text(
                  rutina['nombre'],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  rutina['imagen'],
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // Marcar rutina como completada
                    setState(() {
                      rutina['completada'] = true;
                      rutina['ejecutando'] = false; // liberar flag
                    });

                    Navigator.pop(context); // cerrar pantalla pictograma

                    // Guardar en Firebase
                    await _guardarRutinaFirebase(rutina);

                    // Reproducir "Muy bien"
                    await _reproducirAudio("¡Muy bien!");

                    // Mostrar confeti y estrella al completar rutina
                    _confettiController.play();
                    setState(() {
                      _mostrarEstrella = true;
                    });
                    await Future.delayed(const Duration(seconds: 3));
                    _confettiController.stop();
                    await Future.delayed(const Duration(seconds: 2));
                    setState(() {
                      _mostrarEstrella = false;
                    });

                    // Verificar si todas las rutinas están completadas
                    if (rutinas.every((r) => r['completada'] == true)) {
                      // Reproducir felicitaciones
                      await _reproducirAudio(
                          "¡Felicidades, eres genial, haz ganado una copa!");

                      // Mostrar copa junto con el primer confeti
                      setState(() {
                        _mostrarCopa = true;
                      });

                      // Mostrar confeti 3 veces consecutivas
                      for (int i = 0; i < 3; i++) {
                        _confettiController.play();
                        await Future.delayed(const Duration(seconds: 2));
                        _confettiController.stop();
                        await Future.delayed(const Duration(milliseconds: 500));
                      }

                      // Ocultar copa después de los tres confetis
                      setState(() {
                        _mostrarCopa = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Realizar tarea',
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
      child: Card(
        color: rutina['completada'] == true
            ? const Color.fromARGB(255, 161, 226, 221) // verde suave
            : const Color.fromARGB(255, 4, 243, 111), // naranja mandarina
        child: ListTile(
          contentPadding: const EdgeInsets.all(8),
          leading: SizedBox(
            width: 50,
            height: 50,
            child: Image.asset(
              rutina['imagen'],
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image),
            ),
          ),
          title: Text(
            rutina['nombre'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Hora: ${rutina['hora']}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rutina['modoSecuencia'] == true &&
                  rutina['pasos'] != null &&
                  rutina['pasos'].isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.directions_walk,
                      color: Colors.blueAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PantallaPasos(rutina: rutina),
                      ),
                    );
                  },
                ),
              if (widget.esTutor) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editarRutina(rutina),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () async {
                    // Eliminar localmente
                    setState(() {
                      rutinas.removeAt(index);
                    });
                    // Eliminar en Firebase si tiene id
                    if (rutina.containsKey('idFirebase') &&
                        rutina['idFirebase'] != null) {
                      try {
                        await _firestore
                            .collection('rutinas')
                            .doc(rutina['idFirebase'])
                            .delete();
                      } catch (e) {
                        // noop
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- Agregar rutina -------------------
  void _agregarRutina() {
    TextEditingController rutinaCtrl = TextEditingController();
    TextEditingController horaCtrl = TextEditingController();
    TextEditingController minutoCtrl = TextEditingController();
    String imagenSeleccionada = 'assets/images/pictogramas/desayuno.png';
    bool esSecuencia = false;
    List<TextEditingController> pasosCtrl =
        List.generate(4, (_) => TextEditingController());

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nueva Rutina"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rutinaCtrl,
                  decoration: const InputDecoration(
                    hintText: "Nombre de la rutina",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: horaCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        decoration: const InputDecoration(
                          hintText: "HH",
                          border: OutlineInputBorder(),
                          counterText: "",
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Text(":", style: TextStyle(fontSize: 20)),
                    ),
                    Expanded(
                      child: TextField(
                        controller: minutoCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 2,
                        decoration: const InputDecoration(
                          hintText: "MM",
                          border: OutlineInputBorder(),
                          counterText: "",
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (imagenSeleccionada.isNotEmpty)
                  Image.asset(imagenSeleccionada, width: 80, height: 80),
                const SizedBox(height: 5),
                ElevatedButton(
                  onPressed: () async {
                    final resultado =
                        await _seleccionarPictograma(imagenSeleccionada);
                    if (resultado != null) {
                      setDialogState(() {
                        imagenSeleccionada = resultado;
                      });
                    }
                  },
                  child: const Text("Icono o Imagen"),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Modo Secuencia"),
                  value: esSecuencia,
                  onChanged: (v) {
                    setDialogState(() {
                      esSecuencia = v;
                    });
                  },
                ),
                if (esSecuencia)
                  Column(
                    children: List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextField(
                          controller: pasosCtrl[i],
                          decoration: InputDecoration(
                            hintText: 'Paso ${i + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final hora = int.tryParse(horaCtrl.text);
                final minuto = int.tryParse(minutoCtrl.text);
                if (rutinaCtrl.text.isNotEmpty &&
                    hora != null &&
                    hora >= 0 &&
                    hora <= 23 &&
                    minuto != null &&
                    minuto >= 0 &&
                    minuto <= 59) {
                  final secuencia = esSecuencia
                      ? pasosCtrl
                          .map((e) => e.text.trim())
                          .where((t) => t.isNotEmpty)
                          .toList()
                      : [];
                  final nuevaRutina = {
                    'nombre': rutinaCtrl.text,
                    'imagen': imagenSeleccionada,
                    'hora':
                        '${horaCtrl.text.padLeft(2, '0')}:${minutoCtrl.text.padLeft(2, '0')}',
                    'textoAudio': '¡Hora de ${rutinaCtrl.text}!',
                    'completada': false,
                    'mostrada': false,
                    'modoSecuencia': esSecuencia,
                    'pasos': secuencia,
                  };

                  setState(() {
                    rutinas.add(nuevaRutina);
                  });

                  // Persistir en Firebase (y obtener idFirebase)
                  await _guardarRutinaFirebase(nuevaRutina);

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Ingresa una hora válida (HH:MM)")),
                  );
                }
              },
              child: const Text("Guardar"),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------- Build -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 253, 253, 252), // NARANJA mandarina
      appBar: AppBar(
        title: const Text("Rutinas"),
        backgroundColor: const Color.fromARGB(255, 245, 124, 0),
        // <--- mantuvimos diseño original
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: rutinas.length,
            itemBuilder: (context, index) =>
                _crearTarjetaRutina(rutinas[index], index),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiFinalController,
              blastDirectionality: BlastDirectionality.explosive,
            ),
          ),
          _refuerzoVisual(),
        ],
      ),
      // ---------- Botón flotante (solo visible para Juan/tutor) ----------
floatingActionButton: widget.esTutor
    ? Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.bottomRight,
          child: FloatingActionButton(
            backgroundColor: Colors.grey.shade800, // gris profesional
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
            onPressed: _agregarRutina,
          ),
        ),
      )
    : null,
    );
  }
}

// ------------------- Pantalla de Pasos -------------------
class PantallaPasos extends StatefulWidget {
  final Map<String, dynamic> rutina;
  const PantallaPasos({super.key, required this.rutina});

  @override
  State<PantallaPasos> createState() => _PantallaPasosState();
}

class _PantallaPasosState extends State<PantallaPasos> {
  int pasoActual = 0;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _reproducirPaso();
  }

  Future<void> _reproducirPaso() async {
    final pasos = widget.rutina['pasos'] as List<dynamic>;
    if (pasoActual < pasos.length) {
      await flutterTts.setLanguage("es-ES");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.9);
      await flutterTts.setVolume(1.0);
      await flutterTts.speak(pasos[pasoActual]);
    }
  }

  void _siguientePaso() {
    final pasos = widget.rutina['pasos'] as List<dynamic>;
    if (pasoActual < pasos.length - 1) {
      setState(() {
        pasoActual++;
      });
      _reproducirPaso();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pasos = widget.rutina['pasos'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rutina['nombre']),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              pasos[pasoActual],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _siguientePaso,
              child: Text(
                  pasoActual < pasos.length - 1 ? "Siguiente" : "Terminar"),
            ),
          ],
        ),
      ),
    );
  }
}
