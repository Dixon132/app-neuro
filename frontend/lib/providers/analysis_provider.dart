import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../models/user_model.dart';

final analysisProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>(
  (ref) {
    return AnalysisNotifier();
  },
);

class AnalysisState {
  final List<AnalysisModel> analyses;
  final bool isLoading;
  final String? error;
  final AnalysisModel? currentAnalysis;

  AnalysisState({
    this.analyses = const [],
    this.isLoading = false,
    this.error,
    this.currentAnalysis,
  });

  AnalysisState copyWith({
    List<AnalysisModel>? analyses,
    bool? isLoading,
    String? error,
    AnalysisModel? currentAnalysis,
  }) {
    return AnalysisState(
      analyses: analyses ?? this.analyses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentAnalysis: currentAnalysis ?? this.currentAnalysis,
    );
  }
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final ApiService _apiService = ApiService();

  AnalysisNotifier() : super(AnalysisState());

  Future<void> loadAnalyses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.getAnalysisList();
      final analyses =
          response.map((json) => AnalysisModel.fromJson(json)).toList();
      state = state.copyWith(analyses: analyses, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> uploadEEGBytes(Uint8List fileBytes, String fileName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.uploadEEGBytes(fileBytes, fileName);
      final analysis = AnalysisModel.fromJson(response);
      state = state.copyWith(currentAnalysis: analysis, isLoading: false);
      await loadAnalyses();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAnalysisDetail(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.getAnalysisDetail(id);
      final analysis = AnalysisModel.fromJson(response);
      state = state.copyWith(currentAnalysis: analysis, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
