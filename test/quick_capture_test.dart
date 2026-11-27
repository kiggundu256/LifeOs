import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/models/quick_capture.dart';

void main(){
  test('quick capture maps optional dates, project and conversion metadata',(){
    final now=DateTime(2026,11,27,10);final due=now.add(const Duration(days:1));
    final item=QuickCapture.fromMap({'id':7,'kind':'task','title':'Call client','body':'Discuss proposal','due_at':due.millisecondsSinceEpoch,'reminder_at':null,'scheduled_at':null,'reminder_minutes':0,'project_id':3,'status':'processed','converted_type':'task','converted_id':42,'created_at':now.millisecondsSinceEpoch,'updated_at':now.millisecondsSinceEpoch});
    expect(item.id,7);expect(item.kind,'task');expect(item.dueAt,due);expect(item.projectId,3);expect(item.isProcessed,isTrue);expect(item.convertedId,42);
  });
  test('new capture defaults remain compatible with inbox state',(){
    final now=DateTime(2026,11,27);final item=QuickCapture.fromMap({'id':1,'kind':'note','title':'Idea','created_at':now.millisecondsSinceEpoch,'updated_at':now.millisecondsSinceEpoch});
    expect(item.body,'');expect(item.status,'inbox');expect(item.isProcessed,isFalse);expect(item.reminderMinutes,0);
  });
}
