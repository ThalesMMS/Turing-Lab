import '../models/help_catalog.dart';
import 'help_topic_ids.dart';

final kHelpCatalog = HelpCatalog(
  roots: [
    HelpCategoryDefinition(
      id: HelpTopicIds.gettingStarted,
      icon: 'rocket_launch',
      children: [
        HelpTopicDefinition(
          id: HelpTopicIds.gettingStartedQuickStart,
          icon: 'play_circle',
          relatedTopicIds: [HelpTopicIds.gettingStartedChooseWorkspace],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.gettingStartedNavigation,
          icon: 'navigation',
          relatedTopicIds: [HelpTopicIds.gettingStartedChooseWorkspace],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.gettingStartedChooseWorkspace,
          icon: 'dashboard',
          relatedTopicIds: [HelpTopicIds.fsaEditorOverview],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.gettingStartedFilesAndExamples,
          icon: 'folder_open',
          relatedTopicIds: [HelpTopicIds.fsaEditorFilesAndExamples],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.gettingStartedFirstInput,
          icon: 'play_arrow',
          relatedTopicIds: [HelpTopicIds.fsaEditorSimulationInputAndRun],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.gettingStartedFindHelp,
          icon: 'help_outline',
          relatedTopicIds: [HelpTopicIds.gettingStartedNavigation],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'fsa',
      icon: 'account_tree',
      children: [
        HelpSubsectionDefinition(
          id: 'fsa.editor',
          icon: 'edit',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.fsaEditorOverview,
              icon: 'space_dashboard',
              relatedTopicIds: [
                HelpTopicIds.fsaEditorStates,
                HelpTopicIds.fsaEditorSimulationInputAndRun,
                HelpTopicIds.fsaEditorAlgorithmsOverview,
              ],
            ),
            HelpSubsectionDefinition(
              id: 'fsa.editor.editing',
              icon: 'edit_note',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.fsaEditorSelection,
                  icon: 'near_me',
                  relatedTopicIds: [HelpTopicIds.fsaEditorStates],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.fsaEditorStates,
                  icon: 'radio_button_checked',
                  relatedTopicIds: [HelpTopicIds.fsaEditorTransitions],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.fsaEditorTransitions,
                  icon: 'trending_flat',
                  relatedTopicIds: [HelpTopicIds.fsaEditorDeterminism],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.fsaEditorDeterminism,
                  icon: 'fact_check',
                  relatedTopicIds: [
                    HelpTopicIds.fsaTheoryDfa,
                    HelpTopicIds.fsaTheoryNfa,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.fsaEditorHistoryAndClear,
                  icon: 'history',
                  relatedTopicIds: [HelpTopicIds.fsaEditorSelection],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'fsa.editor.viewport',
              icon: 'zoom_in_map',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.fsaEditorViewportZoom,
                  icon: 'zoom_in',
                  relatedTopicIds: [
                    HelpTopicIds.fsaEditorViewportFitAndReset,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.fsaEditorViewportFitAndReset,
                  icon: 'fit_screen',
                  relatedTopicIds: [
                    HelpTopicIds.fsaEditorViewportAutoLayout,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.fsaEditorViewportAutoLayout,
                  icon: 'auto_awesome_motion',
                  relatedTopicIds: [HelpTopicIds.fsaEditorSelection],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'fsa.editor.simulation',
              icon: 'play_circle',
              children: [
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorSimulationInputAndRun,
                  icon: 'input',
                  relatedTopicIds: [
                    HelpTopicIds.fsaEditorSimulationResultsAndPlayback,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorSimulationResultsAndPlayback,
                  icon: 'slow_motion_video',
                  relatedTopicIds: [
                    HelpTopicIds.fsaTheoryAlphabetAndAcceptance
                  ],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'fsa.editor.algorithms',
              icon: 'auto_awesome',
              children: [
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsOverview,
                  icon: 'hub',
                  relatedTopicIds: [
                    HelpTopicIds.fsaEditorAlgorithmsStepMode,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsRegexToNfa,
                  icon: 'regular_expression',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryNfa],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsNfaToDfa,
                  icon: 'transform',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryDfa],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsRemoveLambda,
                  icon: 'remove_circle_outline',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryEpsilonClosure],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsMinimizeDfa,
                  icon: 'compress',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryEquivalence],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsCompleteDfa,
                  icon: 'add_circle_outline',
                  relatedTopicIds: [
                    HelpTopicIds.fsaEditorAlgorithmsComplementDfa,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsComplementDfa,
                  icon: 'flip',
                  relatedTopicIds: [
                    HelpTopicIds.fsaEditorAlgorithmsCompleteDfa,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsUnion,
                  icon: 'merge_type',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryClosureOperations],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsIntersection,
                  icon: 'call_merge',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryClosureOperations],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsDifference,
                  icon: 'call_split',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryClosureOperations],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsPrefixClosure,
                  icon: 'vertical_align_top',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryClosureOperations],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsSuffixClosure,
                  icon: 'vertical_align_bottom',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryClosureOperations],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsFaToRegex,
                  icon: 'text_fields',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryEquivalence],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsFsaToGrammar,
                  icon: 'schema',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryEquivalence],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsEquivalence,
                  icon: 'compare_arrows',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryEquivalence],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.fsaEditorAlgorithmsStepMode,
                  icon: 'format_list_numbered',
                  relatedTopicIds: [HelpTopicIds.fsaEditorAlgorithmsOverview],
                ),
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaEditorFilesAndExamples,
              icon: 'folder_open',
              relatedTopicIds: [HelpTopicIds.gettingStartedFilesAndExamples],
            ),
          ],
        ),
        HelpSubsectionDefinition(
          id: 'fsa.theory',
          icon: 'school',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryDfa,
              icon: 'account_tree',
              relatedTopicIds: [HelpTopicIds.fsaTheoryNfa],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryNfa,
              icon: 'device_hub',
              relatedTopicIds: [HelpTopicIds.fsaTheoryDfa],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryStates,
              icon: 'radio_button_checked',
              relatedTopicIds: [HelpTopicIds.fsaTheoryTransitions],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryTransitions,
              icon: 'trending_flat',
              relatedTopicIds: [
                HelpTopicIds.fsaTheoryAlphabetAndAcceptance,
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryAlphabetAndAcceptance,
              icon: 'spellcheck',
              relatedTopicIds: [HelpTopicIds.fsaTheoryDfa],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryEpsilon,
              icon: 'looks_one',
              relatedTopicIds: [HelpTopicIds.fsaTheoryEpsilonClosure],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryEpsilonClosure,
              icon: 'all_inclusive',
              relatedTopicIds: [HelpTopicIds.fsaTheoryEpsilon],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryEquivalence,
              icon: 'compare_arrows',
              relatedTopicIds: [
                HelpTopicIds.fsaEditorAlgorithmsEquivalence,
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.fsaTheoryClosureOperations,
              icon: 'functions',
              relatedTopicIds: [HelpTopicIds.fsaEditorAlgorithmsUnion],
            ),
          ],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'grammar',
      icon: 'text_fields',
      children: [
        HelpSubsectionDefinition(
          id: 'grammar.editor',
          icon: 'edit_note',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.grammarEditorOverview,
              icon: 'space_dashboard',
              relatedTopicIds: [HelpTopicIds.grammarEditorProductionSymbols],
            ),
            HelpSubsectionDefinition(
              id: 'grammar.editor.productions',
              icon: 'format_list_bulleted',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.grammarEditorProductionSymbols,
                  icon: 'abc',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryProductions],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.grammarEditorProductionRowsAndAlternatives,
                  icon: 'view_list',
                  relatedTopicIds: [HelpTopicIds.grammarEditorProductionLambda],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.grammarEditorProductionLambda,
                  icon: 'looks_one',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryProductions],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.grammarEditorProductionValidation,
                  icon: 'fact_check',
                  relatedTopicIds: [HelpTopicIds.grammarEditorParserWorkflow],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'grammar.editor.parser',
              icon: 'play_circle',
              children: [
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorParserWorkflow,
                  icon: 'input',
                  relatedTopicIds: [
                    HelpTopicIds.grammarEditorParserAutomaticEarley,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorParserAutomaticEarley,
                  icon: 'auto_awesome',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryCfg],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorParserBruteForce,
                  icon: 'travel_explore',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryDerivations],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorParserCyk,
                  icon: 'grid_on',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryCnf],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorParserLl1,
                  icon: 'first_page',
                  relatedTopicIds: [
                    HelpTopicIds.grammarTheoryPredictiveParsing,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorParserLr,
                  icon: 'last_page',
                  relatedTopicIds: [
                    HelpTopicIds.grammarTheoryPredictiveParsing,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorParserResultsAndSteps,
                  icon: 'format_list_numbered',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryParseTrees],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'grammar.editor.algorithms',
              icon: 'auto_awesome_motion',
              children: [
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithms,
                  icon: 'hub',
                  relatedTopicIds: [HelpTopicIds.grammarEditorAlgorithmsCnf],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithmsCnf,
                  icon: 'filter_list',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryCnf],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithmsGnf,
                  icon: 'format_list_numbered',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryGnf],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithmsRemoveLeftRecursion,
                  icon: 'transform',
                  relatedTopicIds: [
                    HelpTopicIds.grammarTheoryLeftRecursionAndFactoring,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithmsLeftFactor,
                  icon: 'account_tree',
                  relatedTopicIds: [
                    HelpTopicIds.grammarTheoryLeftRecursionAndFactoring,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithmsFirst,
                  icon: 'first_page',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryFirstAndFollow],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithmsFollow,
                  icon: 'last_page',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryFirstAndFollow],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithmsParseTable,
                  icon: 'table_chart',
                  relatedTopicIds: [
                    HelpTopicIds.grammarTheoryPredictiveParsing,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.grammarEditorAlgorithmsAmbiguity,
                  icon: 'help_outline',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryAmbiguity],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'grammar.editor.conversions',
              icon: 'sync_alt',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.grammarEditorConversionsRightLinearToFsa,
                  icon: 'account_tree',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryGrammarFsaPda],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.grammarEditorConversionsPdaGeneral,
                  icon: 'device_hub',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryGrammarFsaPda],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.grammarEditorConversionsPdaStandard,
                  icon: 'layers',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryGrammarFsaPda],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.grammarEditorConversionsPdaGreibach,
                  icon: 'stacked_bar_chart',
                  relatedTopicIds: [HelpTopicIds.grammarTheoryGnf],
                ),
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarEditorFilesAndExamples,
              icon: 'folder_open',
              relatedTopicIds: [HelpTopicIds.gettingStartedFilesAndExamples],
            ),
          ],
        ),
        HelpSubsectionDefinition(
          id: 'grammar.theory',
          icon: 'school',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryCfg,
              icon: 'text_fields',
              relatedTopicIds: [HelpTopicIds.grammarTheoryProductions],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryProductions,
              icon: 'east',
              relatedTopicIds: [HelpTopicIds.grammarTheoryDerivations],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryDerivations,
              icon: 'format_list_numbered',
              relatedTopicIds: [HelpTopicIds.grammarTheoryParseTrees],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryParseTrees,
              icon: 'account_tree',
              relatedTopicIds: [HelpTopicIds.grammarTheoryAmbiguity],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryAmbiguity,
              icon: 'help_center',
              relatedTopicIds: [HelpTopicIds.grammarEditorAlgorithmsAmbiguity],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryLeftRecursionAndFactoring,
              icon: 'call_split',
              relatedTopicIds: [
                HelpTopicIds.grammarEditorAlgorithmsRemoveLeftRecursion,
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryFirstAndFollow,
              icon: 'functions',
              relatedTopicIds: [HelpTopicIds.grammarEditorAlgorithmsFirst],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryPredictiveParsing,
              icon: 'table_view',
              relatedTopicIds: [HelpTopicIds.grammarEditorAlgorithmsParseTable],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryCnf,
              icon: 'filter_list',
              relatedTopicIds: [HelpTopicIds.grammarEditorAlgorithmsCnf],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryGnf,
              icon: 'format_list_numbered',
              relatedTopicIds: [HelpTopicIds.grammarEditorAlgorithmsGnf],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.grammarTheoryGrammarFsaPda,
              icon: 'sync_alt',
              relatedTopicIds: [
                HelpTopicIds.grammarEditorConversionsRightLinearToFsa,
              ],
            ),
          ],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'pda',
      icon: 'layers',
      children: [
        HelpSubsectionDefinition(
          id: 'pda.editor',
          icon: 'edit_note',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.pdaEditorOverview,
              icon: 'space_dashboard',
              relatedTopicIds: [HelpTopicIds.pdaEditorSelectionAndStates],
            ),
            HelpSubsectionDefinition(
              id: 'pda.editor.editing',
              icon: 'edit',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorSelectionAndStates,
                  icon: 'radio_button_checked',
                  relatedTopicIds: [HelpTopicIds.pdaEditorTransitions],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorTransitions,
                  icon: 'trending_flat',
                  relatedTopicIds: [HelpTopicIds.pdaEditorLambdaSwitches],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorLambdaSwitches,
                  icon: 'all_inclusive',
                  relatedTopicIds: [HelpTopicIds.pdaTheoryTransitions],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorHistoryAndClear,
                  icon: 'history',
                  relatedTopicIds: [HelpTopicIds.pdaEditorSelectionAndStates],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'pda.editor.viewport',
              icon: 'zoom_in_map',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorViewportZoom,
                  icon: 'zoom_in',
                  relatedTopicIds: [
                    HelpTopicIds.pdaEditorViewportFitAndReset,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorViewportFitAndReset,
                  icon: 'fit_screen',
                  relatedTopicIds: [
                    HelpTopicIds.pdaEditorViewportAutoLayout,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorViewportAutoLayout,
                  icon: 'auto_awesome_motion',
                  relatedTopicIds: [HelpTopicIds.pdaEditorSelectionAndStates],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'pda.editor.stack',
              icon: 'layers',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorStackInspector,
                  icon: 'view_agenda',
                  relatedTopicIds: [
                    HelpTopicIds.pdaEditorStackInitialSymbolAndAlphabet,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorStackInitialSymbolAndAlphabet,
                  icon: 'abc',
                  relatedTopicIds: [HelpTopicIds.pdaTheoryStack],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.pdaEditorStackOperationPreview,
                  icon: 'preview',
                  relatedTopicIds: [HelpTopicIds.pdaEditorTransitions],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'pda.editor.simulation',
              icon: 'play_circle',
              children: [
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorSimulation,
                  icon: 'input',
                  relatedTopicIds: [
                    HelpTopicIds.pdaEditorSimulationTraceAndStack,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorSimulationTraceAndStack,
                  icon: 'format_list_numbered',
                  relatedTopicIds: [
                    HelpTopicIds.pdaEditorSimulationResultsAndCanvas,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorSimulationResultsAndCanvas,
                  icon: 'slow_motion_video',
                  relatedTopicIds: [HelpTopicIds.pdaTheoryAcceptance],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'pda.editor.algorithms',
              icon: 'auto_awesome',
              children: [
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorAlgorithmsOverview,
                  icon: 'hub',
                  relatedTopicIds: [HelpTopicIds.pdaEditorAlgorithmsToCfg],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorAlgorithmsToCfg,
                  icon: 'transform',
                  relatedTopicIds: [HelpTopicIds.pdaTheoryPdaAndCfg],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorAlgorithmsMinimize,
                  icon: 'compress',
                  relatedTopicIds: [
                    HelpTopicIds.pdaEditorAlgorithmsReachableStates,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorAlgorithmsDeterminism,
                  icon: 'fact_check',
                  relatedTopicIds: [HelpTopicIds.pdaTheoryNondeterminism],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorAlgorithmsReachableStates,
                  icon: 'explore',
                  relatedTopicIds: [HelpTopicIds.pdaEditorAlgorithmsMinimize],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorAlgorithmsLanguage,
                  icon: 'analytics',
                  relatedTopicIds: [
                    HelpTopicIds.pdaTheoryContextFreeLanguages,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.pdaEditorAlgorithmsStackOperations,
                  icon: 'storage',
                  relatedTopicIds: [HelpTopicIds.pdaTheoryStack],
                ),
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pdaEditorFilesAndExamples,
              icon: 'folder_open',
              relatedTopicIds: [HelpTopicIds.gettingStartedFilesAndExamples],
            ),
          ],
        ),
        HelpSubsectionDefinition(
          id: 'pda.theory',
          icon: 'school',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.pdaTheoryPda,
              icon: 'device_hub',
              relatedTopicIds: [HelpTopicIds.pdaTheoryStack],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pdaTheoryStack,
              icon: 'layers',
              relatedTopicIds: [HelpTopicIds.pdaTheoryTransitions],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pdaTheoryTransitions,
              icon: 'trending_flat',
              relatedTopicIds: [HelpTopicIds.pdaEditorTransitions],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pdaTheoryAcceptance,
              icon: 'task_alt',
              relatedTopicIds: [HelpTopicIds.pdaEditorSimulation],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pdaTheoryNondeterminism,
              icon: 'call_split',
              relatedTopicIds: [HelpTopicIds.pdaEditorAlgorithmsDeterminism],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pdaTheoryContextFreeLanguages,
              icon: 'text_fields',
              relatedTopicIds: [HelpTopicIds.pdaTheoryPdaAndCfg],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pdaTheoryPdaAndCfg,
              icon: 'sync_alt',
              relatedTopicIds: [HelpTopicIds.pdaEditorAlgorithmsToCfg],
            ),
          ],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'tm',
      icon: 'memory',
      children: [
        HelpSubsectionDefinition(
          id: 'tm.editor',
          icon: 'edit_note',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.tmEditorOverview,
              icon: 'space_dashboard',
              relatedTopicIds: [HelpTopicIds.tmEditorSelectionAndStates],
            ),
            HelpSubsectionDefinition(
              id: 'tm.editor.editing',
              icon: 'edit',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorSelectionAndStates,
                  icon: 'radio_button_checked',
                  relatedTopicIds: [HelpTopicIds.tmEditorTransitions],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorTransitions,
                  icon: 'trending_flat',
                  relatedTopicIds: [
                    HelpTopicIds.tmEditorReadWriteAndDirection,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorReadWriteAndDirection,
                  icon: 'swap_horiz',
                  relatedTopicIds: [HelpTopicIds.tmTheoryTapeAndHead],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorHistoryAndClear,
                  icon: 'history',
                  relatedTopicIds: [HelpTopicIds.tmEditorSelectionAndStates],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'tm.editor.viewport',
              icon: 'zoom_in_map',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorViewportZoom,
                  icon: 'zoom_in',
                  relatedTopicIds: [HelpTopicIds.tmEditorViewportFitAndReset],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorViewportFitAndReset,
                  icon: 'fit_screen',
                  relatedTopicIds: [HelpTopicIds.tmEditorViewportAutoLayout],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorViewportAutoLayout,
                  icon: 'auto_awesome_motion',
                  relatedTopicIds: [HelpTopicIds.tmEditorSelectionAndStates],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'tm.editor.tape',
              icon: 'view_week',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorTapeInspector,
                  icon: 'view_agenda',
                  relatedTopicIds: [
                    HelpTopicIds.tmEditorTapeBlankAndAlphabet,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorTapeBlankAndAlphabet,
                  icon: 'abc',
                  relatedTopicIds: [HelpTopicIds.tmTheoryTapeAndHead],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.tmEditorTapeHeadAndCurrentCell,
                  icon: 'vertical_align_center',
                  relatedTopicIds: [
                    HelpTopicIds.tmEditorSimulationTraceAndTape
                  ],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'tm.editor.simulation',
              icon: 'play_circle',
              children: [
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorSimulation,
                  icon: 'input',
                  relatedTopicIds: [
                    HelpTopicIds.tmEditorSimulationTraceAndTape,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorSimulationTraceAndTape,
                  icon: 'format_list_numbered',
                  relatedTopicIds: [
                    HelpTopicIds.tmEditorSimulationResultsAndCanvas,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorSimulationResultsAndCanvas,
                  icon: 'slow_motion_video',
                  relatedTopicIds: [HelpTopicIds.tmTheoryHaltingAndAcceptance],
                ),
              ],
            ),
            HelpSubsectionDefinition(
              id: 'tm.editor.algorithms',
              icon: 'auto_awesome',
              children: [
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorAlgorithmsOverview,
                  icon: 'hub',
                  relatedTopicIds: [
                    HelpTopicIds.tmEditorAlgorithmsDecidability,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorAlgorithmsDecidability,
                  icon: 'help_outline',
                  relatedTopicIds: [HelpTopicIds.tmTheoryDecidableLanguages],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorAlgorithmsReachableStates,
                  icon: 'explore',
                  relatedTopicIds: [HelpTopicIds.tmTheoryConfigurations],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorAlgorithmsLanguage,
                  icon: 'analytics',
                  relatedTopicIds: [
                    HelpTopicIds.tmTheoryRecursivelyEnumerable,
                  ],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorAlgorithmsTapeOperations,
                  icon: 'storage',
                  relatedTopicIds: [HelpTopicIds.tmTheoryTapeAndHead],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorAlgorithmsTime,
                  icon: 'timer',
                  relatedTopicIds: [HelpTopicIds.tmTheoryTimeAndSpace],
                ),
                HelpTopicDefinition.structured(
                  id: HelpTopicIds.tmEditorAlgorithmsSpace,
                  icon: 'memory',
                  relatedTopicIds: [HelpTopicIds.tmTheoryTimeAndSpace],
                ),
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.tmEditorFilesAndExamples,
              icon: 'folder_open',
              relatedTopicIds: [HelpTopicIds.gettingStartedFilesAndExamples],
            ),
          ],
        ),
        HelpSubsectionDefinition(
          id: 'tm.theory',
          icon: 'school',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.tmTheoryTm,
              icon: 'memory',
              relatedTopicIds: [HelpTopicIds.tmTheoryTapeAndHead],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.tmTheoryTapeAndHead,
              icon: 'view_week',
              relatedTopicIds: [HelpTopicIds.tmTheoryConfigurations],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.tmTheoryConfigurations,
              icon: 'tune',
              relatedTopicIds: [HelpTopicIds.tmTheoryHaltingAndAcceptance],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.tmTheoryHaltingAndAcceptance,
              icon: 'task_alt',
              relatedTopicIds: [HelpTopicIds.tmEditorSimulation],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.tmTheoryDecidableLanguages,
              icon: 'verified',
              relatedTopicIds: [HelpTopicIds.tmTheoryRecursivelyEnumerable],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.tmTheoryRecursivelyEnumerable,
              icon: 'all_inclusive',
              relatedTopicIds: [HelpTopicIds.tmTheoryDecidableLanguages],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.tmTheoryTimeAndSpace,
              icon: 'query_stats',
              relatedTopicIds: [HelpTopicIds.tmEditorAlgorithmsTime],
            ),
          ],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'regex',
      icon: 'regular_expression',
      children: [
        HelpSubsectionDefinition(
          id: 'regex.editor',
          icon: 'edit_note',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorOverview,
              icon: 'space_dashboard',
              relatedTopicIds: [HelpTopicIds.regexEditorInput],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorInput,
              icon: 'fact_check',
              relatedTopicIds: [HelpTopicIds.regexEditorAlphabet],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorAlphabet,
              icon: 'abc',
              relatedTopicIds: [HelpTopicIds.regexTheoryLiteralsAndGrouping],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorTestStrings,
              icon: 'play_circle',
              relatedTopicIds: [HelpTopicIds.regexTheoryRegularLanguages],
            ),
            HelpSubsectionDefinition(
              id: 'regex.editor.conversions',
              icon: 'sync_alt',
              children: [
                HelpTopicDefinition(
                  id: HelpTopicIds.regexEditorConversions,
                  icon: 'hub',
                  relatedTopicIds: [HelpTopicIds.regexEditorConversionsToNfa],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.regexEditorConversionsToNfa,
                  icon: 'account_tree',
                  relatedTopicIds: [
                    HelpTopicIds.fsaEditorAlgorithmsRegexToNfa,
                  ],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.regexEditorConversionsToDfa,
                  icon: 'transform',
                  relatedTopicIds: [HelpTopicIds.fsaTheoryDfa],
                ),
                HelpTopicDefinition(
                  id: HelpTopicIds.regexEditorConversionsFaToRegex,
                  icon: 'text_fields',
                  relatedTopicIds: [
                    HelpTopicIds.fsaEditorAlgorithmsFaToRegex,
                  ],
                ),
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorSimplification,
              icon: 'compress',
              relatedTopicIds: [HelpTopicIds.regexTheoryPrecedence],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorComplexity,
              icon: 'analytics',
              relatedTopicIds: [HelpTopicIds.regexTheoryKleeneStarAndPlus],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorSampleStrings,
              icon: 'text_snippet',
              relatedTopicIds: [HelpTopicIds.regexEditorTestStrings],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorEquivalence,
              icon: 'compare_arrows',
              relatedTopicIds: [HelpTopicIds.regexTheoryEquivalenceWithFsa],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexEditorEmbeddedFsaPanels,
              icon: 'view_sidebar',
              relatedTopicIds: [HelpTopicIds.fsaEditorOverview],
            ),
          ],
        ),
        HelpSubsectionDefinition(
          id: 'regex.theory',
          icon: 'school',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryRegex,
              icon: 'regular_expression',
              relatedTopicIds: [HelpTopicIds.regexTheoryLiteralsAndGrouping],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryLiteralsAndGrouping,
              icon: 'data_object',
              relatedTopicIds: [
                HelpTopicIds.regexTheoryConcatenationAndUnion,
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryConcatenationAndUnion,
              icon: 'call_split',
              relatedTopicIds: [HelpTopicIds.regexTheoryKleeneStarAndPlus],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryKleeneStarAndPlus,
              icon: 'all_inclusive',
              relatedTopicIds: [HelpTopicIds.regexTheoryOptional],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryOptional,
              icon: 'help_outline',
              relatedTopicIds: [HelpTopicIds.regexTheoryPrecedence],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryPrecedence,
              icon: 'format_list_numbered',
              relatedTopicIds: [HelpTopicIds.regexTheoryLambda],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryLambda,
              icon: 'looks_one',
              relatedTopicIds: [HelpTopicIds.regexTheoryRegularLanguages],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryRegularLanguages,
              icon: 'language',
              relatedTopicIds: [HelpTopicIds.regexTheoryEquivalenceWithFsa],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.regexTheoryEquivalenceWithFsa,
              icon: 'sync_alt',
              relatedTopicIds: [HelpTopicIds.regexEditorConversions],
            ),
          ],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'pumping',
      icon: 'fitness_center',
      children: [
        HelpSubsectionDefinition(
          id: 'pumping.editor',
          icon: 'sports_esports',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorOverview,
              icon: 'space_dashboard',
              relatedTopicIds: [HelpTopicIds.pumpingEditorGame],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorGame,
              icon: 'play_circle',
              relatedTopicIds: [
                HelpTopicIds.pumpingEditorDifficultyAndChallenges,
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorDifficultyAndChallenges,
              icon: 'signal_cellular_alt',
              relatedTopicIds: [HelpTopicIds.pumpingEditorRegularityChoice],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorRegularityChoice,
              icon: 'rule',
              relatedTopicIds: [
                HelpTopicIds.pumpingEditorWitnessAndDecomposition,
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorWitnessAndDecomposition,
              icon: 'schema',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryChooseWitness],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorPumpingChoiceAndSubmit,
              icon: 'send',
              relatedTopicIds: [
                HelpTopicIds.pumpingEditorFeedbackRetryAndPractice,
              ],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorFeedbackRetryAndPractice,
              icon: 'refresh',
              relatedTopicIds: [HelpTopicIds.pumpingEditorProgress],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorProgress,
              icon: 'analytics',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryLimitations],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingEditorResponsiveLayout,
              icon: 'devices',
              relatedTopicIds: [HelpTopicIds.pumpingEditorOverview],
            ),
          ],
        ),
        HelpSubsectionDefinition(
          id: 'pumping.theory',
          icon: 'school',
          children: [
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryStatement,
              icon: 'functions',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryQuantifiers],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryQuantifiers,
              icon: 'format_list_numbered',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryProofStrategy],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryProofStrategy,
              icon: 'route',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryChooseWitness],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryChooseWitness,
              icon: 'text_fields',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryAllDecompositions],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryAllDecompositions,
              icon: 'account_tree',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryContradiction],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryContradiction,
              icon: 'dangerous',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryLimitations],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryLimitations,
              icon: 'warning_amber',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryRegularExample],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryRegularExample,
              icon: 'check_circle',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryNonregularAnbn],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryNonregularAnbn,
              icon: 'balance',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryNonregularWw],
            ),
            HelpTopicDefinition(
              id: HelpTopicIds.pumpingTheoryNonregularWw,
              icon: 'content_copy',
              relatedTopicIds: [HelpTopicIds.pumpingTheoryProofStrategy],
            ),
          ],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'shortcuts',
      icon: 'keyboard',
      children: [
        HelpTopicDefinition(
          id: HelpTopicIds.shortcutsCanvas,
          icon: 'edit',
          relatedTopicIds: [HelpTopicIds.fsaEditorHistoryAndClear],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.shortcutsSimulation,
          icon: 'play_arrow',
          relatedTopicIds: [HelpTopicIds.fsaEditorSimulationInputAndRun],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.shortcutsDialogsAndForms,
          icon: 'dynamic_form',
          relatedTopicIds: [HelpTopicIds.shortcutsFocusNavigation],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.shortcutsFocusNavigation,
          icon: 'keyboard_tab',
          relatedTopicIds: [HelpTopicIds.shortcutsDialogsAndForms],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.shortcutsPlatformModifiers,
          icon: 'devices',
          relatedTopicIds: [HelpTopicIds.shortcutsCanvas],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.shortcutsCancelAndClose,
          icon: 'close',
          relatedTopicIds: [HelpTopicIds.shortcutsDialogsAndForms],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'troubleshooting',
      icon: 'build_circle',
      children: [
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingInvalidAutomata,
          icon: 'error_outline',
          relatedTopicIds: [
            HelpTopicIds.troubleshootingMissingStateMarkers,
            HelpTopicIds.troubleshootingNondeterminism,
          ],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingGrammarInput,
          icon: 'rule',
          relatedTopicIds: [HelpTopicIds.grammarEditorProductionValidation],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingRegexInput,
          icon: 'regular_expression',
          relatedTopicIds: [HelpTopicIds.regexEditorInput],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingSimulationLimits,
          icon: 'timer_off',
          relatedTopicIds: [
            HelpTopicIds.pdaEditorSimulation,
            HelpTopicIds.tmEditorSimulation,
          ],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingParserStrategies,
          icon: 'account_tree',
          relatedTopicIds: [HelpTopicIds.grammarEditorParserWorkflow],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingFileImportExport,
          icon: 'folder_off',
          relatedTopicIds: [HelpTopicIds.gettingStartedFilesAndExamples],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingMissingStateMarkers,
          icon: 'flag',
          relatedTopicIds: [HelpTopicIds.troubleshootingInvalidAutomata],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingNondeterminism,
          icon: 'call_split',
          relatedTopicIds: [HelpTopicIds.fsaEditorDeterminism],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.troubleshootingLostCanvasView,
          icon: 'center_focus_strong',
          relatedTopicIds: [HelpTopicIds.fsaEditorViewportFitAndReset],
        ),
      ],
    ),
    HelpCategoryDefinition(
      id: 'about',
      icon: 'info_outline',
      children: [
        HelpTopicDefinition(
          id: HelpTopicIds.aboutDeveloperAndProject,
          icon: 'code',
          relatedTopicIds: [HelpTopicIds.aboutLicenses],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.aboutLicenses,
          icon: 'policy',
          relatedTopicIds: [HelpTopicIds.aboutAcknowledgments],
          contentKind: HelpTopicContentKind.aboutAndLicenses,
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.aboutAcknowledgments,
          icon: 'groups',
          relatedTopicIds: [HelpTopicIds.aboutDistribution],
        ),
        HelpTopicDefinition(
          id: HelpTopicIds.aboutDistribution,
          icon: 'volunteer_activism',
          relatedTopicIds: [HelpTopicIds.aboutDeveloperAndProject],
        ),
      ],
    ),
  ],
);
