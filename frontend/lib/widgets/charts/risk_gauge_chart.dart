import 'package:flutter/material.dart';
import '../../config/theme.dart';

class RiskGaugeChart extends StatelessWidget {
  final double riskScore;

  const RiskGaugeChart({super.key, required this.riskScore});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                value: riskScore / 100,
                strokeWidth: 20,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getRiskColor()),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${riskScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: _getRiskColor(),
                  ),
                ),
                Text(
                  _getRiskLabel(),
                  style: TextStyle(
                    fontSize: 16,
                    color: _getRiskColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor() {
    if (riskScore > 70) return AppTheme.errorColor;
    if (riskScore > 40) return AppTheme.warningColor;
    return AppTheme.accentColor;
  }

  String _getRiskLabel() {
    if (riskScore > 70) return 'Alto Riesgo';
    if (riskScore > 40) return 'Riesgo Moderado';
    return 'Bajo Riesgo';
  }
}
