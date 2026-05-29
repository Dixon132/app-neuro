import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EEGSignalViewerScreen extends StatefulWidget {
  final int analysisId;
  final String fileName;

  const EEGSignalViewerScreen({
    Key? key,
    required this.analysisId,
    required this.fileName,
  }) : super(key: key);

  @override
  State<EEGSignalViewerScreen> createState() => _EEGSignalViewerScreenState();
}

class _EEGSignalViewerScreenState extends State<EEGSignalViewerScreen> {
  bool _isLoading = true;
  String? _error;
  
  List<FlSpot> _signalData = [];
  int _currentChannel = 0;
  double _startTime = 0;
  double _duration = 10;
  
  String _channelName = '';
  double _samplingRate = 256;
  List<Map<String, dynamic>> _availableChannels = [];
  double _totalDuration = 0;
  Map<String, double> _statistics = {};
  
  // Mapa de información de canales cerebrales
  static const Map<String, Map<String, String>> channelInfo = {
    // Frontales
    'FP1': {'region': 'Frontal Izquierdo', 'function': 'Pensamiento, planificación, personalidad'},
    'FP2': {'region': 'Frontal Derecho', 'function': 'Pensamiento, planificación, personalidad'},
    'F3': {'region': 'Frontal Izquierdo', 'function': 'Movimiento voluntario, habla (área de Broca)'},
    'F4': {'region': 'Frontal Derecho', 'function': 'Movimiento voluntario'},
    'F7': {'region': 'Frontal Lateral Izquierdo', 'function': 'Memoria verbal, emociones'},
    'F8': {'region': 'Frontal Lateral Derecho', 'function': 'Memoria visual, emociones'},
    'FZ': {'region': 'Frontal Central', 'function': 'Control motor, atención'},
    
    // Centrales
    'C3': {'region': 'Central Izquierdo', 'function': 'Movimiento del lado derecho del cuerpo'},
    'C4': {'region': 'Central Derecho', 'function': 'Movimiento del lado izquierdo del cuerpo'},
    'CZ': {'region': 'Central Medio', 'function': 'Coordinación motora'},
    
    // Temporales
    'T3': {'region': 'Temporal Izquierdo', 'function': 'Audición, comprensión del lenguaje'},
    'T4': {'region': 'Temporal Derecho', 'function': 'Audición, reconocimiento de caras'},
    'T5': {'region': 'Temporal Posterior Izquierdo', 'function': 'Memoria, lenguaje'},
    'T6': {'region': 'Temporal Posterior Derecho', 'function': 'Memoria visual'},
    'T7': {'region': 'Temporal Izquierdo', 'function': 'Audición, memoria auditiva'},
    'T8': {'region': 'Temporal Derecho', 'function': 'Audición, procesamiento musical'},
    
    // Parietales
    'P3': {'region': 'Parietal Izquierdo', 'function': 'Sensación táctil, procesamiento espacial'},
    'P4': {'region': 'Parietal Derecho', 'function': 'Sensación táctil, orientación espacial'},
    'PZ': {'region': 'Parietal Central', 'function': 'Integración sensorial'},
    
    // Occipitales
    'O1': {'region': 'Occipital Izquierdo', 'function': 'Visión (campo visual derecho)'},
    'O2': {'region': 'Occipital Derecho', 'function': 'Visión (campo visual izquierdo)'},
    'OZ': {'region': 'Occipital Central', 'function': 'Procesamiento visual central'},
  };
  
  String _getChannelDescription() {
    // Extraer el nombre base del canal (ej: "FP1-F7" -> "FP1")
    final baseName = _channelName.split('-')[0].toUpperCase();
    
    if (channelInfo.containsKey(baseName)) {
      final info = channelInfo[baseName]!;
      return '📍 ${info['region']}\n💡 ${info['function']}';
    }
    
    // Si no está en el mapa, dar descripción genérica
    if (baseName.startsWith('F')) {
      return '📍 Región Frontal\n💡 Pensamiento, planificación, control motor';
    } else if (baseName.startsWith('C')) {
      return '📍 Región Central\n💡 Movimiento y sensación del cuerpo';
    } else if (baseName.startsWith('T')) {
      return '📍 Región Temporal\n💡 Audición, memoria, lenguaje';
    } else if (baseName.startsWith('P')) {
      return '📍 Región Parietal\n💡 Sensación táctil, orientación espacial';
    } else if (baseName.startsWith('O')) {
      return '📍 Región Occipital\n💡 Procesamiento visual';
    }
    
    return '📍 Canal EEG\n💡 Actividad eléctrica cerebral';
  }

  @override
  void initState() {
    super.initState();
    _loadSignalData();
  }

  Future<void> _loadSignalData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost:8000/api/analysis/${widget.analysisId}/signal'
          '?channel=$_currentChannel&start_sec=$_startTime&duration_sec=$_duration',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final List<double> timeList = List<double>.from(data['time']);
        final List<double> amplitudeList = List<double>.from(data['amplitude']);
        
        setState(() {
          _signalData = List.generate(
            timeList.length,
            (i) => FlSpot(timeList[i], amplitudeList[i]),
          );
          _channelName = data['channel_name'];
          _samplingRate = data['sampling_rate'].toDouble();
          _availableChannels = List<Map<String, dynamic>>.from(data['available_channels']);
          _totalDuration = data['total_duration'].toDouble();
          _statistics = Map<String, double>.from(data['statistics']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar señal: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _changeChannel(int newChannel) {
    setState(() {
      _currentChannel = newChannel;
    });
    _loadSignalData();
  }

  void _moveTimeWindow(double offset) {
    setState(() {
      _startTime = (_startTime + offset).clamp(0, _totalDuration - _duration);
    });
    _loadSignalData();
  }

  void _changeDuration(double newDuration) {
    setState(() {
      _duration = newDuration.clamp(5, 30);
      if (_startTime + _duration > _totalDuration) {
        _startTime = (_totalDuration - _duration).clamp(0, _totalDuration);
      }
    });
    _loadSignalData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Visualización de Ondas Cerebrales'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.red)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSignalData,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Información del archivo
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Archivo: ${widget.fileName}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text('Frecuencia de muestreo: ${_samplingRate.toInt()} Hz'),
                              Text('Duración total: ${_totalDuration.toStringAsFixed(1)} segundos'),
                              Text('Canales disponibles: ${_availableChannels.length}'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Selector de canal
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Canal: $_channelName',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              // Descripción del canal
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Text(
                                  _getChannelDescription(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[900],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Seleccionar otro canal:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableChannels.take(12).map((ch) {
                                  final index = ch['index'] as int;
                                  final name = ch['name'] as String;
                                  final isSelected = index == _currentChannel;
                                  
                                  return ChoiceChip(
                                    label: Text(name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) _changeChannel(index);
                                    },
                                    selectedColor: Colors.indigo,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Gráfico de señal
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Señal EEG',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_startTime.toStringAsFixed(1)}s - ${(_startTime + _duration).toStringAsFixed(1)}s',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Container(
                                height: 300,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      horizontalInterval: 50,
                                      verticalInterval: _duration / 10,
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        axisNameWidget: Text('Amplitud (µV)'),
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 50,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        axisNameWidget: Text('Tiempo (s)'),
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 30,
                                          interval: _duration / 5,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _signalData,
                                        isCurved: false,
                                        color: Colors.indigo,
                                        barWidth: 1,
                                        dotData: FlDotData(show: false),
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      touchTooltipData: LineTouchTooltipData(
                                        tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Controles de navegación
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Navegación Temporal',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _startTime > 0
                                        ? () => _moveTimeWindow(-_duration)
                                        : null,
                                    icon: Icon(Icons.arrow_back),
                                    label: Text('Anterior'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _startTime + _duration < _totalDuration
                                        ? () => _moveTimeWindow(_duration)
                                        : null,
                                    icon: Icon(Icons.arrow_forward),
                                    label: Text('Siguiente'),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text('Duración de ventana: ${_duration.toInt()}s'),
                              Slider(
                                value: _duration,
                                min: 5,
                                max: 30,
                                divisions: 5,
                                label: '${_duration.toInt()}s',
                                onChanged: _changeDuration,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Estadísticas del segmento
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estadísticas del Segmento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildStatRow('Media', _statistics['mean'], 'µV'),
                              _buildStatRow('Desv. Estándar', _statistics['std'], 'µV'),
                              _buildStatRow('Mínimo', _statistics['min'], 'µV'),
                              _buildStatRow('Máximo', _statistics['max'], 'µV'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Información educativa
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    '¿Qué estoy viendo?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Esta gráfica muestra la actividad eléctrica de tu cerebro medida en microvoltios (µV). '
                                'Las ondas representan las "conversaciones" entre neuronas. '
                                'Patrones normales muestran ondas suaves y rítmicas, mientras que actividad epiléptica '
                                'puede mostrar picos bruscos (spikes) o descargas repetitivas.',
                                style: TextStyle(color: Colors.blue[900]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Guía de regiones cerebrales
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🧠 Guía de Regiones Cerebrales',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildBrainRegionInfo(
                                '🔵 Frontal (F)',
                                'Pensamiento, planificación, personalidad, movimiento voluntario',
                                'Controla tus decisiones y movimientos conscientes',
                              ),
                              Divider(),
                              _buildBrainRegionInfo(
                                '🟢 Central (C)',
                                'Movimiento y sensación del cuerpo',
                                'Conecta el cerebro con los músculos y la piel',
                              ),
                              Divider(),
                              _buildBrainRegionInfo(
                                '🟡 Temporal (T)',
                                'Audición, memoria, lenguaje',
                                'Procesa sonidos y almacena recuerdos',
                              ),
                              Divider(),
                              _buildBrainRegionInfo(
                                '🟠 Parietal (P)',
                                'Sensación táctil, orientación espacial',
                                'Te ayuda a sentir el tacto y ubicarte en el espacio',
                              ),
                              Divider(),
                              _buildBrainRegionInfo(
                                '🔴 Occipital (O)',
                                'Visión y procesamiento visual',
                                'Interpreta todo lo que ves',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBrainRegionInfo(String title, String function, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          SizedBox(height: 4),
          Text(
            function,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, double? value, String unit) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            value != null ? '${value.toStringAsFixed(2)} $unit' : 'N/A',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
