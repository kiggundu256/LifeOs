import 'package:flutter/material.dart';
import '../models/life_project.dart';
import '../repositories/project_repository.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override State<ProjectsScreen> createState()=>_ProjectsScreenState();
}
class _ProjectsScreenState extends State<ProjectsScreen> {
  final _repo=ProjectRepository();
  final _search=TextEditingController();
  bool _archived=false;
  late Future<List<Map<String,Object?>>> _future;
  @override void initState(){super.initState();_load();}
  @override void dispose(){_search.dispose();super.dispose();}
  void _load()=>_future=_repo.getProjects(query:_search.text,includeArchived:_archived);
  Future<void> _refresh() async {setState(_load);await _future;}
  void _toast(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));

  Future<void> _edit([LifeProject? project]) async {
    final title=TextEditingController(text:project?.title??'');
    final description=TextEditingController(text:project?.description??'');
    final objective=TextEditingController(text:project?.objective??'');
    String priority=project?.priority??'medium', status=project?.status??'active';
    DateTime? start=project?.startAt, due=project?.dueAt;
    final result=await showDialog<bool>(context:context,builder:(context)=>StatefulBuilder(builder:(context,setDialog)=>AlertDialog(
      title:Text(project==null?'Create project':'Edit project'),
      content:SizedBox(width:480,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        TextField(controller:title,autofocus:true,decoration:const InputDecoration(labelText:'Project name',hintText:'What are you building?')),
        const SizedBox(height:10),TextField(controller:objective,minLines:2,maxLines:3,decoration:const InputDecoration(labelText:'Goal / desired outcome')),
        const SizedBox(height:10),TextField(controller:description,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'Description')),
        const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:priority,decoration:const InputDecoration(labelText:'Priority'),items:const [DropdownMenuItem(value:'low',child:Text('Low')),DropdownMenuItem(value:'medium',child:Text('Medium')),DropdownMenuItem(value:'high',child:Text('High'))],onChanged:(v)=>setDialog(()=>priority=v??'medium')),
        const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:status,decoration:const InputDecoration(labelText:'Status'),items:const [DropdownMenuItem(value:'active',child:Text('Active')),DropdownMenuItem(value:'on_hold',child:Text('On hold')),DropdownMenuItem(value:'completed',child:Text('Completed'))],onChanged:(v)=>setDialog(()=>status=v??'active')),
        const SizedBox(height:8),OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,initialDate:start??DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)setDialog(()=>start=d);},icon:const Icon(Icons.play_arrow),label:Text(start==null?'Set start date':'Starts ${start!.day}/${start!.month}/${start!.year}')),
        OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,initialDate:due??start??DateTime.now(),firstDate:DateTime(2000),lastDate:DateTime(2100));if(d!=null)setDialog(()=>due=d);},icon:const Icon(Icons.flag_outlined),label:Text(due==null?'Set deadline':'Deadline ${due!.day}/${due!.month}/${due!.year}')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Save project'))],
    )));
    if(result==true){try{await _repo.saveProject(id:project?.id,title:title.text,description:description.text,objective:objective.text,priority:priority,status:status,startAt:start,dueAt:due);if(mounted){setState(_load);_toast('Project saved');}}catch(e){if(mounted)_toast(e.toString());}}
    title.dispose();description.dispose();objective.dispose();
  }

  Future<void> _detail(LifeProject project) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>_ProjectDetailPage(project:project,repo:_repo)));
    if(mounted)setState(_load);
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Projects'),actions:[IconButton(tooltip:_archived?'Show active':'Show archived',onPressed:(){setState((){_archived=!_archived;_load();});},icon:Icon(_archived?Icons.folder_open:Icons.archive_outlined))]),
    floatingActionButton:_archived?null:FloatingActionButton.extended(onPressed:()=>_edit(),icon:const Icon(Icons.add),label:const Text('New project')),
    body:Column(children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,4,16,12),child:TextField(controller:_search,onChanged:(_)=>setState(_load),decoration:InputDecoration(hintText:'Search projects, goals and descriptions',prefixIcon:const Icon(Icons.search),suffixIcon:_search.text.isEmpty?null:IconButton(onPressed:(){_search.clear();setState(_load);},icon:const Icon(Icons.clear))))),
      Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:_future,builder:(context,snapshot){
        if(snapshot.hasError)return Center(child:Text('Could not load projects: ${snapshot.error}'));
        if(!snapshot.hasData)return const Center(child:CircularProgressIndicator());
        final items=snapshot.data!;
        if(items.isEmpty)return Center(child:Padding(padding:const EdgeInsets.all(32),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.rocket_launch_outlined,size:48,color:Theme.of(context).colorScheme.primary),const SizedBox(height:12),Text(_archived?'No archived projects':'Give your next goal a home',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:6),Text(_archived?'Archived projects will appear here.':'Create a project, break it into milestones and tasks, and watch progress build.',textAlign:TextAlign.center,style:const TextStyle(color:Colors.black54))])));
        return RefreshIndicator(onRefresh:_refresh,child:ListView.separated(padding:const EdgeInsets.fromLTRB(16,4,16,100),itemCount:items.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(context,index){
          final row=items[index],p=LifeProject.fromMap(row);
          final taskCount=row['task_count'] as int? ?? 0,done=row['completed_tasks'] as int? ?? 0;
          final milestones=row['milestone_count'] as int? ?? 0,mDone=row['completed_milestones'] as int? ?? 0;
          final total=taskCount+milestones,completed=done+mDone,progress=total==0?0.0:completed/total;
          final due=p.dueAt;
          return Card(child:InkWell(borderRadius:BorderRadius.circular(18),onTap:()=>_detail(p),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[Expanded(child:Text(p.title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16))),_priority(p.priority),PopupMenuButton<String>(onSelected:(action)async{if(action=='edit')await _edit(p);if(action=='archive'||action=='restore'){await _repo.archiveProject(p.id,action=='archive');if(mounted)setState(_load);}if(action=='delete'){final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete project?'),content:const Text('Its project milestones and project links will be removed. Tasks will remain in your task list.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Delete'))]));if(ok==true){await _repo.deleteProject(p.id);if(mounted)setState(_load);}}},itemBuilder:(_)=>[if(!_archived)const PopupMenuItem(value:'edit',child:Text('Edit')),PopupMenuItem(value:_archived?'restore':'archive',child:Text(_archived?'Restore':'Archive')),const PopupMenuItem(value:'delete',child:Text('Delete'))])]),
            if(p.objective.isNotEmpty)Padding(padding:const EdgeInsets.only(top:4,bottom:10),child:Text(p.objective,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Color(0xFF68758A)))),
            Row(children:[_status(p.status),const Spacer(),if(due!=null)Text('Due ${due.day}/${due.month}/${due.year}',style:const TextStyle(fontSize:12,color:Color(0xFF68758A)))]),
            const SizedBox(height:12),ClipRRect(borderRadius:BorderRadius.circular(8),child:LinearProgressIndicator(value:progress,minHeight:7,backgroundColor:const Color(0xFFE8EDF5))),
            const SizedBox(height:7),Text(total==0?'No tasks or milestones yet':'$completed of $total steps complete · ${(progress*100).round()}%',style:const TextStyle(fontSize:12,color:Color(0xFF68758A))),
          ]))));
        }));
      })),
    ]),
  );
  Widget _priority(String p)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(color:p=='high'?const Color(0xFFFFE9E8):const Color(0xFFEFF3FF),borderRadius:BorderRadius.circular(20)),child:Text('${p.toUpperCase()} PRIORITY',style:TextStyle(fontSize:9,fontWeight:FontWeight.w800,color:p=='high'?const Color(0xFFB84238):const Color(0xFF4567D7))));
  Widget _status(String s)=>Text(s=='on_hold'?'ON HOLD':s.toUpperCase(),style:const TextStyle(fontSize:10,letterSpacing:.6,fontWeight:FontWeight.w800,color:Color(0xFF66738A)));
}

class _ProjectDetailPage extends StatefulWidget {
  const _ProjectDetailPage({required this.project,required this.repo});
  final LifeProject project;final ProjectRepository repo;
  @override State<_ProjectDetailPage> createState()=>_ProjectDetailPageState();
}
class _ProjectDetailPageState extends State<_ProjectDetailPage>{
  late Future<List<Map<String,Object?>>> _tasks,_milestones;
  final _notes=TextEditingController();
  bool _notesLoaded=false;
  @override void initState(){super.initState();_load();}
  @override void dispose(){_notes.dispose();super.dispose();}
  void _load(){_tasks=widget.repo.getTasks(widget.project.id);_milestones=widget.repo.getMilestones(widget.project.id);_loadNotes();}
  Future<void> _loadNotes()async{final s=await widget.repo.getProjectNotes(widget.project.id);if(mounted&&!_notesLoaded){_notes.text=s;_notesLoaded=true;}}
  Future<void> _refresh()async{setState(_load);await Future.wait([_tasks,_milestones]);}
  void _toast(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));

  Future<void> _addTask()async{
    final title=TextEditingController(),notes=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Add project task'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,autofocus:true,decoration:const InputDecoration(labelText:'Task')),TextField(controller:notes,decoration:const InputDecoration(labelText:'Notes'))]),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Add task'))]));
    if(ok==true){try{await widget.repo.addTask(projectId:widget.project.id,title:title.text,notes:notes.text);if(mounted)setState(_load);}catch(e){_toast(e.toString());}}
    title.dispose();notes.dispose();
  }
  Future<void> _addMilestone()async{
    final title=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('New milestone'),content:TextField(controller:title,autofocus:true,decoration:const InputDecoration(labelText:'Milestone')),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancel')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Add milestone'))]));
    if(ok==true){try{await widget.repo.addMilestone(projectId:widget.project.id,title:title.text);if(mounted)setState(_load);}catch(e){_toast(e.toString());}}
    title.dispose();
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.project.title,maxLines:1,overflow:TextOverflow.ellipsis)),
    floatingActionButton:FloatingActionButton.extended(onPressed:_addTask,icon:const Icon(Icons.add_task),label:const Text('Add task')),
    body:RefreshIndicator(onRefresh:_refresh,child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
      if(widget.project.objective.isNotEmpty)Text(widget.project.objective,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w700)),
      if(widget.project.description.isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(widget.project.description,style:const TextStyle(color:Colors.black54,height:1.4))),
      const SizedBox(height:18),
      Row(children:[const Expanded(child:Text('MILESTONES',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1))),TextButton.icon(onPressed:_addMilestone,icon:const Icon(Icons.add),label:const Text('Add'))]),
      FutureBuilder<List<Map<String,Object?>>>(future:_milestones,builder:(c,s){if(!s.hasData)return const LinearProgressIndicator();if(s.data!.isEmpty)return const Text('Add milestones to mark the major stages of this project.',style:TextStyle(color:Colors.black54));return Column(children:s.data!.map((m)=>CheckboxListTile(contentPadding:EdgeInsets.zero,value:(m['is_complete'] as int)==1,title:Text(m['title'] as String),subtitle:m['due_at']==null?null:Text('Due ${DateTime.fromMillisecondsSinceEpoch(m['due_at'] as int).day}/${DateTime.fromMillisecondsSinceEpoch(m['due_at'] as int).month}'),onChanged:(v)async{await widget.repo.setMilestoneComplete(m['id'] as int,v??false);if(mounted)setState(_load);},secondary:IconButton(icon:const Icon(Icons.close),onPressed:()async{await widget.repo.deleteMilestone(m['id'] as int);if(mounted)setState(_load);}))).toList());}),
      const Divider(height:28),
      const Text('PROJECT TASKS',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1)),
      FutureBuilder<List<Map<String,Object?>>>(future:_tasks,builder:(c,s){if(!s.hasData)return const LinearProgressIndicator();if(s.data!.isEmpty)return const Padding(padding:EdgeInsets.symmetric(vertical:14),child:Text('Add the first task for this project.',style:TextStyle(color:Colors.black54)));return Column(children:s.data!.map((t)=>CheckboxListTile(contentPadding:EdgeInsets.zero,value:(t['is_complete'] as int)==1,title:Text(t['title'] as String,style:TextStyle(decoration:(t['is_complete'] as int)==1?TextDecoration.lineThrough:null)),subtitle:(t['notes'] as String).isEmpty?null:Text(t['notes'] as String),onChanged:(v)async{await widget.repo.setTaskComplete(t['id'] as int,v??false);if(mounted)setState(_load);})).toList());}),
      const Divider(height:28),
      const Text('PROJECT NOTES',style:TextStyle(fontWeight:FontWeight.w800,letterSpacing:1)),
      const SizedBox(height:8),
      TextField(controller:_notes,minLines:5,maxLines:12,decoration:const InputDecoration(hintText:'Meeting notes, decisions, research, next steps…')),
      const SizedBox(height:8),Align(alignment:Alignment.centerRight,child:FilledButton.icon(onPressed:()async{await widget.repo.saveProjectNotes(widget.project.id,_notes.text);if(mounted)_toast('Project notes saved');},icon:const Icon(Icons.save_outlined),label:const Text('Save notes'))),
    ])),
  );
}
