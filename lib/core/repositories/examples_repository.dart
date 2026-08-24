import '../models/asset_example.dart';
import '../models/fsa.dart';
import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/regex_preset.dart';
import '../models/tm.dart';
import '../result.dart';

abstract interface class ExamplesRepository {
  Future<Result<AssetExample<FSA>>> loadTypedFsaExample(String name);
  Future<Result<AssetExample<Grammar>>> loadTypedCfgExample(String name);
  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name);
  Future<Result<AssetExample<TM>>> loadTypedTmExample(String name);
  Future<Result<AssetExample<RegexPreset>>> loadTypedRegexExample(String name);
  Future<ListResult<AssetExample<FSA>>> loadAllTypedFsaExamples();
  Future<ListResult<AssetExample<Grammar>>> loadAllTypedCfgExamples();
  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples();
  Future<ListResult<AssetExample<TM>>> loadAllTypedTmExamples();
  Future<ListResult<AssetExample<RegexPreset>>> loadAllTypedRegexExamples();
}
