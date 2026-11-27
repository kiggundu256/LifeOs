import 'package:flutter/material.dart';
import 'models/idea.dart';
import 'models/life_task.dart';
import 'screens/ai_assistant_screen.dart';
import 'screens/performance_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/brain_vault_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/quick_capture_screen.dart';
import 'services/reminder_service.dart';
import 'repositories/lifeos_repository.dart';

void main() => runApp(const LifeOsApp());
class LifeOsApp extends StatelessWidget {
  const LifeOsApp({super.key});
  @override Widget build(BuildContext context) {
    const seed=Color(0xFF4567D7);
    return MaterialApp(title:'LifeOS',debugShowCheckedModeBanner:false,theme:ThemeData(
      useMaterial3:true,colorScheme:ColorScheme.fromSeed(seedColor:seed,brightness:Brightness.light),
      scaffoldBackgroundColor:const Color(0xFFF6F8FC),canvasColor:const Color(0xFFF6F8FC),
      appBarTheme:const AppBarTheme(backgroundColor:Color(0xFFF6F8FC),foregroundColor:Color(0xFF19243A),elevation:0,centerTitle:false,titleTextStyle:TextStyle(color:Color(0xFF19243A),fontSize:22,fontWeight:FontWeight.w800)),
      cardTheme:CardThemeData(elevation:0,margin:EdgeInsets.zero,color:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18),side:const BorderSide(color:Color(0xFFE8ECF4)))),
      navigationBarTheme:NavigationBarThemeData(backgroundColor:Colors.white,indicatorColor:const Color(0xFFE8EEFF),elevation:0,height:72,labelTextStyle:WidgetStateProperty.resolveWith((states)=>TextStyle(fontSize:11,fontWeight:states.contains(WidgetState.selected)?FontWeight.w800:FontWeight.w500))),
      floatingActionButtonTheme:const FloatingActionButtonThemeData(backgroundColor:Color(0xFF315FE7),foregroundColor:Colors.white),
      inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:14),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xFFE0E6F0))),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xFFE0E6F0))),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:const BorderSide(color:Color(0xFF4567D7),width:1.5))),
    ),home:const LifeOsShell());
  }
}
class LifeOsShell extends StatefulWidget { const LifeOsShell({super.key}); @override State<LifeOsShell> createState()=>_LifeOsShellState(); }
class _LifeOsShellState extends State<LifeOsShell> {
  int _index=0;
  final _homeKey=GlobalKey<_HomeScreenState>();
  final _performanceKey=GlobalKey<PerformanceScreenState>();
  final _plannerKey=GlobalKey<PlannerScreenState>();
  final _repository=LifeosRepository();
  @override Widget build(BuildContext context){
    final pages=<Widget>[
      HomeScreen(key:_homeKey,repository:_repository,onNavigate:(index){setState(()=>_index=index);if(index==4)_plannerKey.currentState?.refreshData();}),
      TasksScreen(repository:_repository),BrainVaultScreen(repository:_repository),const ProjectsScreen(),
      PlannerScreen(key:_plannerKey,repository:_repository),PerformanceScreen(key:_performanceKey,repository:_repository),
      QuickCaptureScreen(repository:_repository),const AiAssistantScreen(),
    ];
    return Scaffold(body:SafeArea(child:IndexedStack(index:_index,children:pages)),
      floatingActionButton:_index==6?null:FloatingActionButton.small(tooltip:'Quick Capture',onPressed:()=>setState(()=>_index=6),child:const Icon(Icons.add_rounded)),
      bottomNavigationBar:NavigationBar(selectedIndex:_index,onDestinationSelected:(value){setState(()=>_index=value);if(value==0)_homeKey.currentState?.refreshData();if(value==4)_plannerKey.currentState?.refreshData();if(value==5)_performanceKey.currentState?.refreshData();},destinations:const[
        NavigationDestination(icon:Icon(Icons.space_dashboard_outlined),selectedIcon:Icon(Icons.space_dashboard),label:'Home'),
        NavigationDestination(icon:Icon(Icons.checklist_outlined),selectedIcon:Icon(Icons.checklist),label:'Tasks'),
        NavigationDestination(icon:Icon(Icons.auto_awesome_mosaic_outlined),selectedIcon:Icon(Icons.auto_awesome_mosaic),label:'Second Brain'),
        NavigationDestination(icon:Icon(Icons.folder_outlined),selectedIcon:Icon(Icons.folder),label:'Projects'),
        NavigationDestination(icon:Icon(Icons.calendar_month_outlined),selectedIcon:Icon(Icons.calendar_month),label:'Planner'),
        NavigationDestination(icon:Icon(Icons.insights_outlined),selectedIcon:Icon(Icons.insights),label:'Growth'),
        NavigationDestination(icon:Icon(Icons.add_circle_outline),selectedIcon:Icon(Icons.add_circle),label:'Capture'),
        NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),selectedIcon:Icon(Icons.auto_awesome),label:'AI'),
      ]));
  }
}
