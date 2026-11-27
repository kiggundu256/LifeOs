import 'package:flutter/material.dart';
import '../services/ai_assistant_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override State<AiAssistantScreen> createState()=>_AiAssistantScreenState();
}
class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _service=AiAssistantService();
  final _input=TextEditingController();
  final _scroll=ScrollController();
  final List<_Message> _messages=[_Message('assistant','Hello! I’m your LifeOS copilot. Ask me to help plan your day, think through a project, or make sense of your notes. You decide when LifeOS data is shared.')];
  AiAssistantConfig? _config;
  bool _includeContext=false,_sending=false;
  @override void initState(){super.initState();_loadConfig();}
  @override void dispose(){_input.dispose();_scroll.dispose();_service.dispose();super.dispose();}
  Future<void> _loadConfig()async{final value=await _service.getConfig();if(mounted)setState(()=>_config=value);}
  void _toast(String value)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(value)));

  Future<void> _settings()async{
    final current=_config??await _service.getConfig();
    final endpoint=TextEditingController(text:current.endpoint),model=TextEditingController(text:current.model),key=TextEditingController();
    final saved=await showModalBottomSheet<bool>(context:context,isScrollControlled:true,showDragHandle:true,builder:(context)=>Padding(padding:EdgeInsets.fromLTRB(20,8,20,MediaQuery.of(context).viewInsets.bottom+24),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[
      Text('AI provider settings',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
      const SizedBox(height:8),const Text('Connect an OpenAI-compatible provider. Your API key is stored in Android secure storage and is never committed to GitHub. Provider usage may incur charges.',style:TextStyle(color:Colors.black54)),
      const SizedBox(height:16),TextField(controller:endpoint,decoration:const InputDecoration(labelText:'API base URL',hintText:'https://api.openai.com/v1')),
      const SizedBox(height:10),TextField(controller:model,decoration:const InputDecoration(labelText:'Model name',hintText:'gpt-4o-mini')),
      const SizedBox(height:10),TextField(controller:key,obscureText:true,autocorrect:false,enableSuggestions:false,decoration:InputDecoration(labelText:current.hasApiKey?'Replace API key':'API key',hintText:current.hasApiKey?'Saved securely; leave blank to keep it':'Paste your provider API key')),
      const SizedBox(height:16),FilledButton(onPressed:(){if(key.text.trim().isEmpty&&!current.hasApiKey){_toast('Enter an API key.');return;}Navigator.pop(context,true);},child:const Text('Save provider settings')),
      if(current.hasApiKey)TextButton(onPressed:()async{await _service.clearApiKey();if(context.mounted)Navigator.pop(context,false);},child:const Text('Remove saved API key')),
    ]))));
    if(saved==true){try{await _service.saveConfig(endpoint:endpoint.text,model:model.text,apiKey:key.text);_toast('AI provider settings saved securely.');}catch(e){_toast('Settings not saved: $e');}}
    await _loadConfig();endpoint.dispose();model.dispose();key.dispose();
  }

  Future<void> _send()async{
    final text=_input.text.trim();if(text.isEmpty||_sending)return;
    var config=_config??await _service.getConfig();
    if(!config.hasApiKey){await _settings();config=await _service.getConfig();if(!config.hasApiKey)return;}
    setState((){_messages.add(_Message('user',text));_input.clear();_sending=true;});
    _jumpToBottom();
    try{
      final history=_messages.where((m)=>m.role=='user'||m.role=='assistant').toList();
      final prior=history.length>1?history.sublist(0,history.length-1).map((m)=>{'role':m.role,'content':m.text}).toList():<Map<String,String>>[];
      final reply=await _service.sendMessage(message:text,conversation:prior,includeLifeOsContext:_includeContext);
      if(mounted)setState(()=>_messages.add(_Message('assistant',reply)));
    }catch(e){if(mounted)setState(()=>_messages.add(_Message('assistant','I couldn’t complete that request. ${e.toString().replaceFirst('Bad state: ','')}')));}
    finally{if(mounted){setState(()=>_sending=false);_jumpToBottom();}}
  }
  void _jumpToBottom(){WidgetsBinding.instance.addPostFrameCallback((_){if(_scroll.hasClients)_scroll.animateTo(_scroll.position.maxScrollExtent,duration:const Duration(milliseconds:250),curve:Curves.easeOut);});}

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Row(children:[Icon(Icons.auto_awesome,color:Color(0xFF4567D7)),SizedBox(width:9),Text('LifeOS AI')]),actions:[
      IconButton(tooltip:'Provider settings',onPressed:_settings,icon:const Icon(Icons.tune)),
      IconButton(tooltip:'Clear conversation',onPressed:()=>setState((){_messages..clear()..add(_Message('assistant','Conversation cleared. What would you like to work on?'));}),icon:const Icon(Icons.delete_sweep_outlined)),
    ]),
    body:Column(children:[
      if(_config?.hasApiKey!=true)Container(width:double.infinity,margin:const EdgeInsets.fromLTRB(16,4,16,8),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFEAF0FF),borderRadius:BorderRadius.circular(16)),child:Row(children:[const Icon(Icons.link,color:Color(0xFF315FE7)),const SizedBox(width:10),const Expanded(child:Text('Connect an AI provider to start chatting.',style:TextStyle(fontWeight:FontWeight.w600))),TextButton(onPressed:_settings,child:const Text('Connect'))])),
      Expanded(child:ListView.builder(controller:_scroll,padding:const EdgeInsets.fromLTRB(16,12,16,18),itemCount:_messages.length+(_sending?1:0),itemBuilder:(context,index){
        if(index==_messages.length)return const Align(alignment:Alignment.centerLeft,child:Padding(padding:EdgeInsets.all(12),child:SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2))));
        final m=_messages[index],mine=m.role=='user';
        return Align(alignment:mine?Alignment.centerRight:Alignment.centerLeft,child:Container(constraints:const BoxConstraints(maxWidth:340),margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.symmetric(horizontal:15,vertical:12),decoration:BoxDecoration(color:mine?const Color(0xFF315FE7):Colors.white,borderRadius:BorderRadius.circular(18),border:mine?null:Border.all(color:const Color(0xFFE8ECF4))),child:SelectableText(m.text,style:TextStyle(color:mine?Colors.white:const Color(0xFF253149),height:1.4))));
      })),
      Container(padding:const EdgeInsets.fromLTRB(14,8,14,14),decoration:const BoxDecoration(color:Colors.white,border:Border(top:BorderSide(color:Color(0xFFE8ECF4)))),child:Column(children:[
        Row(children:[Switch(value:_includeContext,onChanged:(v)=>setState(()=>_includeContext=v)),const Expanded(child:Text('Use my LifeOS context',style:TextStyle(fontWeight:FontWeight.w600))),IconButton(tooltip:'What gets shared?',onPressed:()=>showDialog(context:context,builder:(context)=>AlertDialog(title:const Text('LifeOS context sharing'),content:const Text('When enabled, a limited snapshot of your open tasks, recent Second Brain notes, projects and inbox captures is sent to your configured AI provider with your message. It is off by default. Attachments and API keys are not included.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Got it'))])),icon:const Icon(Icons.info_outline,size:20)]),
        Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:TextField(controller:_input,minLines:1,maxLines:5,textCapitalization:TextCapitalization.sentences,onSubmitted:(_)=>_send(),decoration:const InputDecoration(hintText:'Ask LifeOS AI…',filled:true,fillColor:Color(0xFFF6F8FC),border:OutlineInputBorder(borderSide:BorderSide.none,borderRadius:BorderRadius.all(Radius.circular(18)))))),const SizedBox(width:8),IconButton.filled(onPressed:_sending?null:_send,style:IconButton.styleFrom(backgroundColor:const Color(0xFF315FE7),foregroundColor:Colors.white),icon:Icon(_sending?Icons.hourglass_top:Icons.send_rounded))]),
      ])),
    ]),
  );
}
class _Message{const _Message(this.role,this.text);final String role,text;}
