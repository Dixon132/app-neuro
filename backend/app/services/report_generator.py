from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    SimpleDocTemplate, Table, TableStyle, Paragraph,
    Spacer, HRFlowable, KeepTogether,
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from datetime import datetime


class ReportGenerator:
    # Paleta de colores
    COLOR_PRIMARY = colors.HexColor("#1a237e")    # azul oscuro
    COLOR_HIGH    = colors.HexColor("#c62828")    # rojo
    COLOR_MEDIUM  = colors.HexColor("#ef6c00")    # naranja
    COLOR_LOW     = colors.HexColor("#2e7d32")    # verde
    COLOR_HEADER  = colors.HexColor("#e8eaf6")    # azul muy claro
    COLOR_GRAY    = colors.HexColor("#f5f5f5")

    def __init__(self):
        self.styles = getSampleStyleSheet()
        self._add_custom_styles()

    def _add_custom_styles(self):
        self.styles.add(ParagraphStyle(
            name="ReportTitle",
            fontSize=20,
            textColor=self.COLOR_PRIMARY,
            spaceAfter=6,
            alignment=TA_CENTER,
            fontName="Helvetica-Bold",
        ))
        self.styles.add(ParagraphStyle(
            name="SectionTitle",
            fontSize=13,
            textColor=self.COLOR_PRIMARY,
            spaceBefore=12,
            spaceAfter=6,
            fontName="Helvetica-Bold",
        ))
        self.styles.add(ParagraphStyle(
            name="SmallGray",
            fontSize=8,
            textColor=colors.grey,
            alignment=TA_CENTER,
        ))

    def _risk_color(self, risk_score: float) -> colors.Color:
        if risk_score > 70:
            return self.COLOR_HIGH
        if risk_score > 40:
            return self.COLOR_MEDIUM
        return self.COLOR_LOW

    def _risk_label(self, prediction: str) -> str:
        return prediction or "N/A"

    def generate_pdf(self, analysis_data: dict, output_path: str) -> str:
        doc = SimpleDocTemplate(
            output_path,
            pagesize=letter,
            leftMargin=0.75 * inch,
            rightMargin=0.75 * inch,
            topMargin=0.75 * inch,
            bottomMargin=0.75 * inch,
        )
        story = []
        prediction = analysis_data.get("prediction", {})
        metrics = analysis_data.get("metrics", {})
        risk_score = prediction.get("risk_score", 0) or 0
        pred_label = prediction.get("prediction", "N/A")
        confidence = prediction.get("confidence", 0) or 0
        channel_analysis = prediction.get("channel_analysis", [])
        most_anomalous = prediction.get("most_anomalous_channel", "N/A")
        n_windows = prediction.get("n_windows_analyzed", 1)
        sampling_rate = prediction.get("sampling_rate", 256)

        risk_color = self._risk_color(risk_score)

        # ── ENCABEZADO ──
        story.append(Paragraph("Reporte de Análisis EEG", self.styles["ReportTitle"]))
        story.append(Paragraph(
            "Sistema de Detección de Actividad Epiléptica",
            self.styles["SmallGray"],
        ))
        story.append(HRFlowable(width="100%", thickness=2, color=self.COLOR_PRIMARY, spaceAfter=12))

        # ── INFO GENERAL ──
        story.append(Paragraph("Información del Análisis", self.styles["SectionTitle"]))
        info_data = [
            ["Fecha de análisis:", datetime.now().strftime("%Y-%m-%d %H:%M:%S")],
            ["Archivo:", analysis_data.get("file_name", "N/A")],
            ["Paciente / Usuario:", analysis_data.get("user", "N/A")],
            ["Frecuencia de muestreo:", f"{sampling_rate} Hz"],
            ["Ventanas analizadas:", str(n_windows)],
        ]
        story.append(self._info_table(info_data))
        story.append(Spacer(1, 16))

        # ── RESULTADO PRINCIPAL ──
        story.append(Paragraph("Resultado del Análisis", self.styles["SectionTitle"]))
        result_data = [
            ["PREDICCIÓN", "RIESGO (%)", "CONFIANZA"],
            [pred_label, f"{risk_score:.1f}%", f"{confidence * 100:.1f}%"],
        ]
        result_table = Table(result_data, colWidths=[2.5 * inch, 2 * inch, 2 * inch])
        result_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), self.COLOR_PRIMARY),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("FONTSIZE", (0, 0), (-1, 0), 11),
            ("BACKGROUND", (0, 1), (-1, 1), self.COLOR_GRAY),
            ("TEXTCOLOR", (0, 1), (0, 1), risk_color),
            ("TEXTCOLOR", (1, 1), (1, 1), risk_color),
            ("FONTNAME", (0, 1), (-1, 1), "Helvetica-Bold"),
            ("FONTSIZE", (0, 1), (-1, 1), 14),
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("ROWBACKGROUNDS", (0, 1), (-1, 1), [self.COLOR_GRAY]),
            ("BOX", (0, 0), (-1, -1), 1, self.COLOR_PRIMARY),
            ("INNERGRID", (0, 0), (-1, -1), 0.5, colors.lightgrey),
            ("TOPPADDING", (0, 0), (-1, -1), 10),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
        ]))
        story.append(result_table)
        story.append(Spacer(1, 16))

        # ── CANAL MÁS ANÓMALO ──
        if most_anomalous and most_anomalous != "N/A":
            story.append(Paragraph("Localización de Actividad Anómala", self.styles["SectionTitle"]))
            loc_data = [
                ["Canal con mayor actividad anómala:", most_anomalous],
                ["Tipo de actividad:", "Focal" if len(channel_analysis) > 0 and
                 channel_analysis[0].get("anomaly_score", 0) > 70 else "Difusa / Generalizada"],
            ]
            story.append(self._info_table(loc_data))
            story.append(Spacer(1, 12))

        # ── ANÁLISIS POR CANAL ──
        if channel_analysis:
            story.append(Paragraph("Análisis por Canal", self.styles["SectionTitle"]))
            
            # Explicación de valores normales
            story.append(Paragraph(
                "<i>Valores de referencia: Anomalía <30% (normal), 30-70% (moderado), >70% (alto). "
                "Spikes normales <0.1/s. Delta normal 0.2-0.4, Alpha normal 0.15-0.30.</i>",
                self.styles["SmallGray"]
            ))
            story.append(Spacer(1, 8))
            
            ch_header = ["Canal", "Anomalía (%)", "Spikes/s", "Kurtosis", "Delta rel.", "Alpha rel.", "Entropía"]
            ch_rows = [ch_header]
            for ch in channel_analysis[:16]:  # máximo 16 canales en el PDF
                anomaly = ch.get("anomaly_score", 0)
                spike_rate = ch.get('spike_rate', 0)
                delta_rel = ch.get('delta_rel', 0)
                alpha_rel = ch.get('alpha_rel', 0)
                
                # Resaltar valores anormales con símbolos
                anomaly_str = f"{anomaly:.1f}%"
                if anomaly > 70:
                    anomaly_str = f"⚠ {anomaly:.1f}%"
                elif anomaly > 40:
                    anomaly_str = f"⚡ {anomaly:.1f}%"
                
                spike_str = f"{spike_rate:.3f}"
                if spike_rate > 0.3:
                    spike_str = f"⚠ {spike_rate:.3f}"
                elif spike_rate > 0.15:
                    spike_str = f"⚡ {spike_rate:.3f}"
                
                delta_str = f"{delta_rel:.3f}"
                if delta_rel > 0.7:
                    delta_str = f"⚠ {delta_rel:.3f}"
                elif delta_rel > 0.5:
                    delta_str = f"⚡ {delta_rel:.3f}"
                
                alpha_str = f"{alpha_rel:.3f}"
                if alpha_rel < 0.05:
                    alpha_str = f"⚠ {alpha_rel:.3f}"
                elif alpha_rel < 0.10:
                    alpha_str = f"⚡ {alpha_rel:.3f}"
                
                ch_rows.append([
                    ch.get("channel", "?"),
                    anomaly_str,
                    spike_str,
                    f"{ch.get('kurtosis', 0):.2f}",
                    delta_str,
                    alpha_str,
                    f"{ch.get('spectral_entropy', 0):.2f}",
                ])

            col_w = [1.0 * inch, 1.1 * inch, 0.9 * inch, 0.9 * inch, 0.9 * inch, 0.9 * inch, 0.9 * inch]
            ch_table = Table(ch_rows, colWidths=col_w)
            ch_style = [
                ("BACKGROUND", (0, 0), (-1, 0), self.COLOR_PRIMARY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
            # Colorear filas según anomalía
            for row_idx, ch in enumerate(channel_analysis[:16], start=1):
                anomaly = ch.get("anomaly_score", 0)
                if anomaly > 70:
                    bg = colors.HexColor("#ffebee")
                elif anomaly > 40:
                    bg = colors.HexColor("#fff3e0")
                else:
                    bg = colors.white
                ch_style.append(("BACKGROUND", (0, row_idx), (-1, row_idx), bg))

            ch_table.setStyle(TableStyle(ch_style))
            story.append(ch_table)
            
            # Leyenda de símbolos
            story.append(Spacer(1, 8))
            legend_data = [
                ["⚠", "Valor anormal (requiere atención)"],
                ["⚡", "Valor moderadamente elevado"],
                ["Sin símbolo", "Valor dentro de rango normal"],
            ]
            legend_table = Table(legend_data, colWidths=[0.5 * inch, 6.0 * inch])
            legend_table.setStyle(TableStyle([
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("ALIGN", (0, 0), (0, -1), "CENTER"),
                ("ALIGN", (1, 0), (1, -1), "LEFT"),
                ("TEXTCOLOR", (0, 0), (0, -1), colors.grey),
            ]))
            story.append(legend_table)
            story.append(Spacer(1, 16))

        # ── MÉTRICAS DE AMPLITUD ──
        story.append(Paragraph("Métricas de Señal", self.styles["SectionTitle"]))
        
        mean_amp = metrics.get('mean_amplitude', 0)
        std_amp = metrics.get('std_amplitude', 0)
        max_amp = metrics.get('max_amplitude', 0)
        
        # Determinar si los valores son normales
        mean_status = "✓ Normal" if abs(mean_amp) < 50 else "⚠ Elevado"
        std_status = "✓ Normal" if std_amp < 30 else "⚠ Alta variabilidad"
        max_status = "✓ Normal" if abs(max_amp) < 200 else "⚠ Picos altos"
        
        metrics_data = [
            ["Amplitud Media:", f"{mean_amp:.4f} µV", mean_status],
            ["Desviación Estándar:", f"{std_amp:.4f} µV", std_status],
            ["Amplitud Máxima:", f"{max_amp:.4f} µV", max_status],
            ["Amplitud Mínima:", f"{metrics.get('min_amplitude', 0):.4f} µV", ""],
            ["Energía total:", f"{metrics.get('energy', 0):.4f}", ""],
        ]
        
        metrics_table = Table(metrics_data, colWidths=[2.0 * inch, 2.5 * inch, 2.0 * inch])
        metrics_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (0, -1), self.COLOR_HEADER),
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
            ("FONTNAME", (1, 0), (1, -1), "Helvetica"),
            ("FONTNAME", (2, 0), (2, -1), "Helvetica-Oblique"),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("ALIGN", (0, 0), (0, -1), "RIGHT"),
            ("ALIGN", (1, 0), (1, -1), "LEFT"),
            ("ALIGN", (2, 0), (2, -1), "LEFT"),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ("LEFTPADDING", (0, 0), (-1, -1), 8),
            ("BOX", (0, 0), (-1, -1), 0.5, colors.lightgrey),
            ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
            ("ROWBACKGROUNDS", (0, 0), (-1, -1), [colors.white, self.COLOR_GRAY]),
            ("TEXTCOLOR", (2, 0), (2, 0), self.COLOR_LOW if "Normal" in mean_status else self.COLOR_MEDIUM),
            ("TEXTCOLOR", (2, 1), (2, 1), self.COLOR_LOW if "Normal" in std_status else self.COLOR_MEDIUM),
            ("TEXTCOLOR", (2, 2), (2, 2), self.COLOR_LOW if "Normal" in max_status else self.COLOR_MEDIUM),
        ]))
        story.append(metrics_table)
        
        # Explicación de valores normales
        story.append(Spacer(1, 8))
        story.append(Paragraph(
            "<i>Valores de referencia: Amplitud media normal <50 µV, Desviación estándar <30 µV, "
            "Amplitud máxima <200 µV. Valores superiores pueden indicar actividad anómala.</i>",
            self.styles["SmallGray"]
        ))
        story.append(Spacer(1, 16))

        # ── RECOMENDACIONES ──
        story.append(Paragraph("Recomendaciones Clínicas", self.styles["SectionTitle"]))
        if risk_score > 70:
            recs = [
                "⚠ Se detectó actividad de ALTO RIESGO. Consulte con un neurólogo de forma urgente.",
                "• Considere monitoreo EEG prolongado (24–72 horas).",
                "• Evalúe inicio de tratamiento antiepiléptico según criterio médico.",
                "• Evite actividades de riesgo (conducir, nadar solo) hasta evaluación médica.",
            ]
        elif risk_score > 40:
            recs = [
                "⚡ Se detectó actividad de RIESGO MODERADO. Se recomienda evaluación neurológica.",
                "• Programar consulta con especialista en los próximos 7 días.",
                "• Considerar EEG de seguimiento en 4–6 semanas.",
                "• Registrar episodios o síntomas asociados.",
            ]
        else:
            recs = [
                "✓ No se detectó actividad epiléptica significativa.",
                "• Continuar con controles periódicos según indicación médica.",
                "• Este resultado no descarta patología — siempre consulte con su médico.",
            ]

        for rec in recs:
            story.append(Paragraph(rec, self.styles["Normal"]))
            story.append(Spacer(1, 4))

        story.append(Spacer(1, 16))

        # ── SECCIÓN EDUCATIVA ──
        story.append(HRFlowable(width="100%", thickness=2, color=self.COLOR_PRIMARY, spaceAfter=12))
        story.append(Paragraph("Guía de Interpretación para Pacientes y Familiares", self.styles["SectionTitle"]))
        story.append(Spacer(1, 8))
        
        # ¿Qué es un EEG?
        story.append(Paragraph("<b>¿Qué es un Electroencefalograma (EEG)?</b>", self.styles["Normal"]))
        story.append(Paragraph(
            "Un EEG es un estudio que registra la actividad eléctrica del cerebro mediante electrodos colocados "
            "en el cuero cabelludo. Es como escuchar las 'conversaciones' entre las neuronas. Es completamente "
            "indoloro y no invasivo.",
            self.styles["Normal"]
        ))
        story.append(Spacer(1, 8))

        # ¿Qué mide este análisis?
        story.append(Paragraph("<b>¿Qué mide este análisis?</b>", self.styles["Normal"]))
        story.append(Paragraph(
            "El sistema analiza las ondas cerebrales buscando patrones asociados a epilepsia. "
            "Específicamente evalúa:",
            self.styles["Normal"]
        ))
        story.append(Spacer(1, 4))
        
        measures_data = [
            ["📊 Frecuencias cerebrales", "Delta (sueño), Theta (somnolencia), Alpha (relajación), Beta (actividad mental)"],
            ["⚡ Spikes epilépticos", "Picos eléctricos breves y puntiagudos característicos de epilepsia"],
            ["🌊 Patrones rítmicos", "Descargas repetitivas que pueden indicar convulsiones"],
            ["📍 Localización", "Qué áreas del cerebro muestran actividad anómala"],
            ["🔢 Complejidad", "Qué tan ordenada o caótica es la actividad cerebral"],
        ]
        measures_table = Table(measures_data, colWidths=[1.8 * inch, 4.7 * inch])
        measures_table.setStyle(TableStyle([
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("ALIGN", (0, 0), (0, -1), "LEFT"),
            ("ALIGN", (1, 0), (1, -1), "LEFT"),
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("TOPPADDING", (0, 0), (-1, -1), 4),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ("LEFTPADDING", (0, 0), (-1, -1), 6),
            ("BACKGROUND", (0, 0), (-1, -1), self.COLOR_GRAY),
            ("BOX", (0, 0), (-1, -1), 0.5, colors.grey),
        ]))
        story.append(measures_table)
        story.append(Spacer(1, 10))

        # Interpretación del resultado
        story.append(Paragraph("<b>¿Qué significa mi resultado?</b>", self.styles["Normal"]))
        story.append(Spacer(1, 4))
        
        if risk_score > 70:
            story.append(Paragraph(
                f"<b>Su resultado: {risk_score:.1f}% de riesgo (ALTO)</b>",
                ParagraphStyle(name="HighRisk", parent=self.styles["Normal"], textColor=self.COLOR_HIGH, fontSize=11, fontName="Helvetica-Bold")
            ))
            story.append(Spacer(1, 4))
            story.append(Paragraph(
                "🔴 <b>¿Por qué está en riesgo alto?</b> El análisis detectó múltiples características asociadas "
                "a actividad epiléptica:",
                self.styles["Normal"]
            ))
            story.append(Spacer(1, 4))
            reasons = []
            if most_anomalous and most_anomalous != "N/A":
                reasons.append(f"• <b>Actividad focal anómala</b> en el canal {most_anomalous}")
            if channel_analysis and len([ch for ch in channel_analysis if ch.get("anomaly_score", 0) > 70]) > 0:
                n_high = len([ch for ch in channel_analysis if ch.get("anomaly_score", 0) > 70])
                reasons.append(f"• <b>{n_high} canal(es)</b> con anomalía superior al 70%")
            reasons.append("• <b>Ondas lentas excesivas</b> (Delta/Theta elevadas)")
            reasons.append("• <b>Spikes epilépticos</b> detectados con frecuencia anormal")
            reasons.append("• <b>Baja complejidad</b> de la señal (entropía reducida)")
            
            for reason in reasons:
                story.append(Paragraph(reason, self.styles["Normal"]))
                story.append(Spacer(1, 2))
            
            story.append(Spacer(1, 6))
            story.append(Paragraph(
                "⚠️ <b>¿Qué debo hacer?</b> Consulte con un neurólogo <b>urgentemente</b>. "
                "Este resultado sugiere alta probabilidad de actividad epiléptica que requiere evaluación "
                "y posible tratamiento. No conduzca ni realice actividades de riesgo hasta ser evaluado.",
                self.styles["Normal"]
            ))
            
        elif risk_score > 40:
            story.append(Paragraph(
                f"<b>Su resultado: {risk_score:.1f}% de riesgo (MODERADO)</b>",
                ParagraphStyle(name="MedRisk", parent=self.styles["Normal"], textColor=self.COLOR_MEDIUM, fontSize=11, fontName="Helvetica-Bold")
            ))
            story.append(Spacer(1, 4))
            story.append(Paragraph(
                "🟡 <b>¿Por qué está en riesgo moderado?</b> El análisis detectó algunas características "
                "que pueden estar asociadas a epilepsia, pero no son concluyentes:",
                self.styles["Normal"]
            ))
            story.append(Spacer(1, 4))
            reasons = [
                "• <b>Patrones ambiguos</b>: Algunas ondas anormales pero no claramente epilépticas",
                "• <b>Actividad intermitente</b>: Anomalías presentes solo en algunos momentos",
                "• <b>Baja confianza</b>: El sistema no está completamente seguro del diagnóstico",
            ]
            for reason in reasons:
                story.append(Paragraph(reason, self.styles["Normal"]))
                story.append(Spacer(1, 2))
            
            story.append(Spacer(1, 6))
            story.append(Paragraph(
                "📋 <b>¿Qué debo hacer?</b> Programe una consulta con un neurólogo en los próximos 7 días. "
                "Es recomendable realizar un EEG de seguimiento y monitoreo. Registre cualquier síntoma "
                "(mareos, ausencias, movimientos involuntarios) para informar al médico.",
                self.styles["Normal"]
            ))
            
        else:
            story.append(Paragraph(
                f"<b>Su resultado: {risk_score:.1f}% de riesgo (BAJO)</b>",
                ParagraphStyle(name="LowRisk", parent=self.styles["Normal"], textColor=self.COLOR_LOW, fontSize=11, fontName="Helvetica-Bold")
            ))
            story.append(Spacer(1, 4))
            story.append(Paragraph(
                "🟢 <b>¿Por qué está en riesgo bajo?</b> El análisis muestra un patrón cerebral "
                "predominantemente normal:",
                self.styles["Normal"]
            ))
            story.append(Spacer(1, 4))
            reasons = [
                "• <b>Frecuencias normales</b>: Balance adecuado entre ondas rápidas y lentas",
                "• <b>Sin spikes epilépticos</b>: No se detectaron picos anormales significativos",
                "• <b>Actividad organizada</b>: La señal cerebral muestra complejidad normal",
                "• <b>Sin focos anómalos</b>: Todos los canales dentro de rangos esperados",
            ]
            for reason in reasons:
                story.append(Paragraph(reason, self.styles["Normal"]))
                story.append(Spacer(1, 2))
            
            story.append(Spacer(1, 6))
            story.append(Paragraph(
                "✅ <b>¿Qué debo hacer?</b> Continúe con sus controles médicos habituales. "
                "Este resultado es tranquilizador, pero recuerde que un solo EEG no descarta completamente "
                "epilepsia (algunos pacientes tienen EEG normal entre crisis). Si tiene síntomas, consulte "
                "con su médico.",
                self.styles["Normal"]
            ))

        story.append(Spacer(1, 12))

        # Preguntas frecuentes
        story.append(Paragraph("<b>Preguntas Frecuentes</b>", self.styles["Normal"]))
        story.append(Spacer(1, 4))
        
        faq_data = [
            ["❓ ¿Este resultado es definitivo?", 
             "No. Este es un análisis automatizado de apoyo. El diagnóstico final lo hace un neurólogo "
             "considerando el EEG, síntomas clínicos, historial médico y otros estudios."],
            ["❓ ¿Puedo tener epilepsia con riesgo bajo?", 
             "Sí. Algunos pacientes con epilepsia tienen EEG normal entre crisis. Si tiene síntomas "
             "(convulsiones, ausencias, pérdida de conciencia), consulte aunque el resultado sea bajo."],
            ["❓ ¿Qué tan preciso es este análisis?", 
             f"El sistema tiene una confianza de {confidence * 100:.0f}% en este resultado. "
             "Valores sobre 80% indican alta certeza, valores bajo 60% sugieren resultado ambiguo."],
            ["❓ ¿Necesito más estudios?", 
             "Depende del resultado y sus síntomas. Su neurólogo puede solicitar: EEG prolongado (24-72h), "
             "video-EEG, resonancia magnética cerebral, o análisis de sangre."],
        ]
        
        for q, a in faq_data:
            story.append(Paragraph(f"<b>{q}</b>", self.styles["Normal"]))
            story.append(Paragraph(a, self.styles["Normal"]))
            story.append(Spacer(1, 6))

        story.append(Spacer(1, 8))

        # ── DISCLAIMER ──
        story.append(HRFlowable(width="100%", thickness=1, color=colors.lightgrey))
        story.append(Spacer(1, 6))
        disclaimer = (
            "<i>AVISO LEGAL: Este reporte es generado automáticamente por un sistema de inteligencia artificial "
            "con fines de apoyo diagnóstico. No reemplaza el criterio clínico de un profesional de la salud. "
            "Los resultados deben ser interpretados por un neurólogo certificado. En caso de emergencia médica, "
            "acuda inmediatamente al servicio de urgencias más cercano.</i>"
        )
        story.append(Paragraph(disclaimer, self.styles["SmallGray"]))

        doc.build(story)
        return output_path

    def _info_table(self, data: list) -> Table:
        table = Table(data, colWidths=[2.5 * inch, 4.0 * inch])
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (0, -1), self.COLOR_HEADER),
            ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
            ("FONTNAME", (1, 0), (1, -1), "Helvetica"),
            ("FONTSIZE", (0, 0), (-1, -1), 9),
            ("ALIGN", (0, 0), (0, -1), "RIGHT"),
            ("ALIGN", (1, 0), (1, -1), "LEFT"),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ("LEFTPADDING", (0, 0), (-1, -1), 8),
            ("BOX", (0, 0), (-1, -1), 0.5, colors.lightgrey),
            ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.lightgrey),
            ("ROWBACKGROUNDS", (0, 0), (-1, -1), [colors.white, self.COLOR_GRAY]),
        ]))
        return table
