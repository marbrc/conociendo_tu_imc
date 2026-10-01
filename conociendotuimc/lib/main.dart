// importamos los widgets de material que son los botones cajas de texto
import 'package:flutter/material.dart';
// este sirve para limitar lo que se puede escribir en los campos y para cerrar la app
import 'package:flutter/services.dart';

// la funcion main es donde arranca todo la app
void main() {
  runApp(const MyApp());
}

// esta clase es la app completa, solo configura el tema y dice cual es la pantalla principal
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // quita la etiqueta roja de debug de la esquina
      debugShowCheckedModeBanner: false,
      title: 'Conociendo tu IMC',
      // tema azul para toda la app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 33, 82, 243)),
        useMaterial3: true,
      ),
      home: const PantallaImc(),
    );
  }
}

// ---------------- logica del imc ----------------

// aplica la formula imc = peso / (estatura en metros)^2
double calcularImc(double pesoKg, double estaturaCm) {
  // la estatura viene en cm pero la formula pide metros, entonces dividimos entre 100
  final metros = estaturaCm / 100;
  final imc = pesoKg / (metros * metros);
  // toStringAsFixed(1) redondea a 1 decimal pero lo regresa como texto
  // por eso lo volvemos a convertir a double con double.parse
  // esto se hace ANTES de clasificar para que 24.96 se vuelva 25.0 y sea sobrepeso
  return double.parse(imc.toStringAsFixed(1));
}

// calcula el peso ideal aproximado con la formula imc 22 x estatura^2
double calcularPesoIdeal(double estaturaCm) {
  final metros = estaturaCm / 100;
  final ideal = 22 * (metros * metros);
  // tambien lo redondeamos a 1 decimal
  return double.parse(ideal.toStringAsFixed(1));
}

// clasifica el imc ya redondeado en las 4 categorias
String obtenerCategoria(double imc) {
  // usamos < y no <= por eso el 18.5 ya no es bajo peso
  if (imc < 18.5) {
    return 'Bajo peso';
  } else if (imc < 25) {
    return 'Peso normal';
  } else if (imc < 30) {
    return 'Sobrepeso';
  } else {
    return 'Obesidad';
  }
}

// regresa el mensajito que le toca a cada categoria
String obtenerMensaje(String categoria) {
  if (categoria == 'Bajo peso') {
    return 'Te recomendamos mejorar tu alimentacion';
  } else if (categoria == 'Peso normal') {
    return 'Sigue asi, vas muy bien!';
  } else if (categoria == 'Sobrepeso') {
    return 'Te conviene cuidar tu alimentacion y actividad fisica';
  } else {
    return 'Es importante buscar orientacion profesional';
  }
}

// regresa el color que le toca a cada categoria, ojo que va afuera de la otra funcion
Color obtenerColor(String categoria) {
  if (categoria == 'Bajo peso') {
    return Colors.blue;
  } else if (categoria == 'Peso normal') {
    return Colors.green;
  } else if (categoria == 'Sobrepeso') {
    return Colors.orange;
  } else {
    return Colors.red;
  }
}

// ---------------- pantalla ----------------

// es StatefulWidget porque la etiqueta de resultado cambia y necesitamos setState
class PantallaImc extends StatefulWidget {
  const PantallaImc({super.key});

  @override
  State<PantallaImc> createState() => _PantallaImcState();
}

class _PantallaImcState extends State<PantallaImc> {
  // un controlador por cada caja de texto, con esto leemos y borramos lo que escribieron
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _edadCtrl = TextEditingController();
  final TextEditingController _pesoCtrl = TextEditingController();
  final TextEditingController _estaturaCtrl = TextEditingController();

  // aqui guardamos el texto que sale en la etiqueta, si esta vacio no se muestra nada
  String _resultado = '';

  // aqui guardamos el color del borde de la etiqueta, empieza en tu azul marino
  Color _colorResultado = const Color.fromARGB(255, 19, 45, 240);

  // libera los controladores cuando se cierra la pantalla, es buena practica
  @override
  void dispose() {
    _nombreCtrl.dispose();
    _edadCtrl.dispose();
    _pesoCtrl.dispose();
    _estaturaCtrl.dispose();
    super.dispose();
  }

  // metodo reutilizable para abrir un dialogo con titulo y mensaje
  void _mostrarDialogo(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: Text(mensaje),
          actions: [
            // el boton aceptar solo cierra el dialogo
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // se ejecuta al presionar calcular imc
  void _calcular() {
    // trim quita los espacios de sobra al inicio y al final
    final nombre = _nombreCtrl.text.trim();
    // tryParse regresa null si no es un numero valido, asi la app no se cae
    final peso = double.tryParse(_pesoCtrl.text.trim());
    final estatura = double.tryParse(_estaturaCtrl.text.trim());
    // la edad es opcional, si la dejan vacia queda en null y no pasa nada
    final edad = int.tryParse(_edadCtrl.text.trim());

    // validacion 1, si falta el nombre o el peso o la estatura avisamos con dialogo
    if (nombre.isEmpty || peso == null || estatura == null) {
      _mostrarDialogo(
        'Datos incompletos',
        'Escribe tu nombre, tu peso y tu estatura con numeros validos',
      );
      return;
    }

    // validacion 2, el peso debe estar entre 20 y 300 y la estatura entre 80 y 250
    if (peso < 20 || peso > 300 || estatura < 80 || estatura > 250) {
      _mostrarDialogo(
        'Datos fuera de rango',
        'El peso debe estar entre 20 y 300 kg y la estatura entre 80 y 250 cm',
      );
      return;
    }

    // calculamos el imc ya redondeado y luego lo clasificamos
    final imc = calcularImc(peso, estatura);
    final categoria = obtenerCategoria(imc);
    final mensaje = obtenerMensaje(categoria);
    final pesoIdeal = calcularPesoIdeal(estatura);

    // armamos el mensaje con interpolacion de cadenas ($variable mete el valor en el texto)
    String texto =
        'Hola $nombre\nTu IMC es $imc\nEstatus: $categoria\n$mensaje\nPeso ideal aproximado: $pesoIdeal kg';

    // si escribieron la edad y es menor de 18 le agregamos un aviso al mensaje
    // la edad no se usa en el calculo, solo para este aviso
    if (edad != null && edad < 18) {
      texto = '$texto\nAviso: eres menor de 18 anos y el IMC es una referencia para adultos';
    }

    // setState avisa a flutter que algo cambio para que redibuje la etiqueta
    setState(() {
      _resultado = texto;
      // guardamos el color del borde segun la categoria que salio
      _colorResultado = obtenerColor(categoria);
    });

    // mostramos el mismo resultado en el dialogo
    _mostrarDialogo('Resultado', texto);
  }

  // borra los 4 campos y la etiqueta
  void _limpiar() {
    _nombreCtrl.clear();
    _edadCtrl.clear();
    _pesoCtrl.clear();
    _estaturaCtrl.clear();
    setState(() {
      _resultado = '';
    });
  }

  // recalcular solo borra la etiqueta y deja los datos que ya escribieron
  void _recalcular() {
    setState(() {
      _resultado = '';
    });
  }

  // cierra la aplicacion
  void _salir() {
    SystemNavigator.pop();
  }

  // decoracion que se repite en las cajas de texto, asi no escribimos lo mismo varias veces
  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: const Color.fromARGB(255, 11, 38, 244)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // fondo azul clarito
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Conociendo tu IMC'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 49, 16, 236),
        foregroundColor: Colors.white,
      ),
      // scroll para que no se tape nada cuando sale el teclado
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // iconito de adorno arriba
            const Icon(Icons.monitor_weight_outlined, size: 70, color: Color.fromARGB(255, 61, 37, 243)),
            const SizedBox(height: 10),
            const Text(
              'Escribe tus datos para conocer tu IMC',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),

            // campo del nombre, textCapitalization.words pone mayuscula al inicio de cada palabra
            TextField(
              controller: _nombreCtrl,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.words,
              decoration: _decoracion('Nombre completo', Icons.person),
            ),
            const SizedBox(height: 14),

            // campo de la edad, es opcional y solo acepta digitos enteros
            TextField(
              controller: _edadCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoracion('Edad (opcional)', Icons.cake),
            ),
            const SizedBox(height: 14),

            // campo del peso, teclado decimal y solo deja un punto y maximo 2 decimales
            TextField(
              controller: _pesoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: _decoracion('Peso (kg)', Icons.fitness_center),
            ),
            const SizedBox(height: 14),

            // campo de estatura, teclado numerico y solo acepta digitos enteros
            TextField(
              controller: _estaturaCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoracion('Estatura (cm)', Icons.height),
            ),
            const SizedBox(height: 22),

            // boton principal, ElevatedButton es el que sale relleno de color
            ElevatedButton.icon(
              onPressed: _calcular,
              icon: const Icon(Icons.calculate),
              label: const Text('Calcular IMC'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 47, 33, 243),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // limpiar y recalcular van juntos en una fila, Expanded hace que midan lo mismo
            Row(
              children: [
                Expanded(
                  // boton limpiar, OutlinedButton es el que solo tiene borde
                  child: OutlinedButton.icon(
                    onPressed: _limpiar,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Limpiar datos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  // boton recalcular, solo borra la etiqueta
                  child: OutlinedButton.icon(
                    onPressed: _recalcular,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Recalcular'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // boton salir, TextButton es el mas sencillo sin fondo ni borde
            TextButton.icon(
              onPressed: _salir,
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Salir'),
            ),
            const SizedBox(height: 16),

            // la etiqueta solo se dibuja si _resultado tiene algo escrito
            if (_resultado.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  // el borde ahora cambia de color segun la categoria
                  border: Border.all(color: _colorResultado, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      _resultado,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    // aclaracion chiquita de que no es diagnostico medico
                    const Text(
                      'El IMC es una referencia general, no un diagnostico medico',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}