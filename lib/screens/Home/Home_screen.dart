// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/community_settings_popup.dart';
import '../../widgets/home_post_popup.dart';
import '../../widgets/message_widget.dart';
import '../../widgets/post_interaction_popup.dart';
import '../../widgets/screen_info_popup.dart';
import '../Profile/profile_screen.dart';
import '../Resources/resources_screen.dart';
import '../Experiences/experiences_screen.dart';
import '../Timetable/timetable_screen.dart';
import 'conversation_screen.dart';

enum _FeedView { all, replies, connections, learn }

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key, this.showGuidelines = false});

  final bool showGuidelines;

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  static const _green = Color(0xFF0DA64A);

  _FeedView _feedView = _FeedView.all;
  int _bottomIndex = 0;
  String _learnCategory = 'Getting started';

  static const _learnCategories = [
    'Getting started',
    'Learning styles',
    'Teaching',
    'Planning',
    'Wellbeing',
    'Community',
    'Progress',
    'Legal',
  ];

  static const _learnTopics = [
    'Where Do I Start With Homeschooling?',
    'Do I Need to Follow the National Curriculum?',
    'Your First 30 Days of Homeschooling',
    'How Much Time Should Homeschooling Take?',
    'Do You Need a Homeschool Room?',
    'Homeschooling Multiple Children',
    "What If My Child Doesn't Want to Learn?",
  ];

  static const _learningStyleTopics = [
    'Traditional',
    'Charlotte Mason',
    'Montessori',
    'Classical Education',
    'Unschooling',
    'Unit Studies',
  ];

  static const _teachingTopics = [
    'Teaching vs Facilitating Learning',
    'How Children Learn Best',
    'The Art of Asking Good Questions',
    'How to Teach Without Giving Your Child the Answer',
    'Reading Together',
    'Teaching Writing at Home',
  ];

  static const _planningTopics = [
    'How to Build a Homeschool Routine',
    'Do You Need a Timetable?',
    'Planning a Week of Learning',
    'Planning a Term',
    "Planning Around Your Child's Interests",
    'How to Plan Without Overplanning',
  ];

  static const _wellbeingTopics = [
    'Understanding Your Child as a Learner',
    'Building Independence',
    'Helping Your Child Develop Confidence',
    'When Learning Feels Difficult',
    'Avoiding Homeschool Burnout',
    'Creating a Healthy Balance',
  ];

  static const _communityLearnTopics = [
    'Do Homeschooled Children Need Socialisation?',
    'Building Friendships Outside School',
    'Finding Your Homeschool Community',
    'How to Make Homeschool Friends',
    'Learning With Other Families',
    'Organising a Homeschool Meetup',
  ];

  static const _progressTopics = [
    'How Do I Know If My Child Is Learning?',
    'Do You Need Tests?',
    'Assessment Without Exams',
    'Keeping a Learning Portfolio',
    "Recording Your Child's Progress",
    'Using Projects as Evidence of Learning',
  ];

  static const _legalTopics = [
    'Home Education in England: What Parents Need to Know',
    'Your Legal Responsibilities',
    'Do You Have to Follow the National Curriculum?',
    'Leaving School to Home Educate',
    'Working With Your Local Council',
    'Home Education & SEN',
    'Home Education & GCSEs',
  ];

  static const _learnArticles = <String, List<String>>{
    'Where Do I Start With Homeschooling?': [
      'Starting homeschooling can feel overwhelming, but you don’t need to have everything planned before you begin. Start by understanding your child’s needs, interests and learning style, then look into the legal requirements for homeschooling where you live.',
      'Next, explore the different approaches to homeschooling. You might prefer a structured timetable, learning through projects, following your child’s interests, or a mixture of different methods.',
      'Keep your first routine simple. Choose a few subjects or topics to focus on, and balance learning at home with books, conversations, outdoor activities, museums, workshops and other real-world experiences.',
      'Most importantly, give yourself time to find what works. Your first plan doesn’t need to be perfect—you can change your approach as you learn more about your child and your own homeschooling style.',
    ],
    'Do I Need to Follow the National Curriculum?': [
      "If you're homeschooling in England, you don't have to follow the National Curriculum. You have the freedom to choose what, how and when your child learns, whether that's through a structured curriculum, child-led learning, projects, experiences or a mixture of approaches.",
      "You are responsible for providing a full-time education that is suitable for your child's age, ability, aptitude and educational needs. This doesn't mean recreating school at home — learning can happen through books, conversations, practical activities, museums, nature, sports and everyday life.",
      'The rules are different across the UK, so make sure you check the guidance for where you live. For England, you can find the latest official guidance on GOV.UK.',
    ],
    'Your First 30 Days of Homeschooling': [
      'The first 30 days are about finding your rhythm, not getting everything perfect. Spend time understanding how your child learns, what interests them and what they enjoy. Start with a simple routine rather than trying to recreate a school timetable.',
      'Choose a few key areas to focus on, such as reading, maths and writing, then leave plenty of room for curiosity and exploration. Use books, conversations, practical activities, nature and experiences to make learning part of everyday life.',
      "Most importantly, give yourself permission to adjust. If something isn't working, change it. Keep notes on what your child is enjoying and where they may need more support. By the end of your first month, you'll have a much better idea of what works for your family.",
    ],
    'How Much Time Should Homeschooling Take?': [
      "Homeschooling doesn't have to mean spending six hours a day at a desk. The right amount of learning time depends on your child's age, needs, approach and how you structure your day. Learning can happen through lessons, reading, conversations, play and everyday experiences.",
      "For many families, focused learning can take just a few hours, with the rest of the day providing opportunities to explore interests and develop practical skills. A museum visit, nature walk, cooking activity or project can all contribute to your child's education.",
      "Focus on quality rather than the clock. If your child is engaged and learning, you don't need to fill every hour with lessons. Build a routine that gives your child enough structure while leaving room for curiosity, breaks and family life.",
    ],
    'Do You Need a Homeschool Room?': [
      "You don't need a dedicated homeschool room to educate your child at home. A kitchen table, sofa, garden, library or local museum can all become places for learning. What matters most is having a comfortable space where your child can focus when they need to.",
      "A dedicated space can be useful if you have the room, but it doesn't need to look like a classroom. A small desk, books, stationery and somewhere to keep resources may be all you need.",
      'Remember, homeschooling gives you the freedom to learn beyond the walls of your home. Some of the best learning can happen through experiences, conversations, exploration and everyday life.',
    ],
    'Homeschooling Multiple Children': [
      "Homeschooling multiple children can feel challenging, but you don't need to teach every child separately all day. Look for opportunities to learn together, especially through subjects like science, history, art, reading and projects, while adapting the activity to each child's age and ability.",
      'Try creating a simple routine with shared learning time and individual time. One child might work independently while you read with another, then you can come back together for a practical activity or discussion.',
      "Most importantly, remember that each child is different. You don't need identical lessons or identical progress. Give each child space to follow their interests while creating opportunities for siblings to learn, collaborate and explore together.",
    ],
    "What If My Child Doesn't Want to Learn?": [
      "If your child doesn't want to learn, don't assume they're simply being difficult. They may be tired, bored, frustrated, overwhelmed or struggling with something they don't yet understand. Start by listening and trying to understand what's behind the resistance.",
      "Look for ways to make learning more engaging. Connect subjects to their interests, take learning outdoors, use practical activities or turn a question they're curious about into a project. Sometimes changing the environment or taking a short break can make a big difference.",
      "You don't need to win a battle over every lesson. Curiosity is a powerful starting point. Give your child opportunities to have some choice while maintaining a consistent expectation that learning remains part of their day.",
    ],
    'Traditional': [
      "Traditional homeschooling follows a more structured, school-like approach. Parents usually plan lessons, choose a curriculum and set regular times for subjects such as maths, English, science and history.",
      'This approach can work well for families who enjoy clear routines, textbooks, worksheets and measurable goals. It can also make it easier to track progress and prepare children for formal exams such as GCSEs.',
      "You don't have to copy school exactly. Many families use the structure of traditional homeschooling while adding flexibility through projects, educational experiences, outdoor learning and their child's interests.",
    ],
    'Charlotte Mason': [
      'Charlotte Mason homeschooling focuses on developing the whole child, not simply completing lessons. It uses rich, engaging books known as “living books”, short lessons, narration, nature study, art, music and plenty of time outdoors.',
      'Rather than relying heavily on worksheets and memorisation, children are encouraged to pay attention, form their own ideas and explain what they have learned. Narration is often used to help children process and communicate their understanding.',
      "Charlotte Mason can suit families who want a gentler, literature-rich approach with a balance of structure and exploration. You can also adapt elements of the method to fit your family's needs.",
    ],
    'Montessori': [
      'Montessori homeschooling encourages children to learn through hands-on experiences, independence and exploration. Instead of directing every activity, parents create an environment where children can choose meaningful activities and work at their own pace.',
      'Learning often includes practical life skills, sensory activities, maths, language, science and nature. Materials are designed to help children explore concepts independently, with the parent acting more as a guide than a traditional teacher.',
      "A Montessori-inspired homeschool doesn't need to perfectly recreate a Montessori classroom. You can simply bring its principles into everyday life by encouraging independence, concentration, curiosity and learning through doing.",
    ],
    'Classical Education': [
      'Classical education focuses on building a strong foundation of knowledge, reasoning and communication. It is traditionally organised around the Trivium: Grammar, Logic and Rhetoric, with learning becoming more analytical as children grow.',
      'Children typically study subjects such as literature, history, mathematics, science, languages and the arts, often with an emphasis on reading, memorisation, discussion and developing a broad base of knowledge.',
      'This approach can suit families who enjoy structured learning, rich books and thoughtful discussion. It can also be adapted with projects, practical activities and educational experiences to make learning more engaging.',
    ],
    'Unschooling': [
      "Unschooling is a child-led approach to learning where there is less emphasis on a fixed timetable or traditional curriculum. Instead, parents use their child's questions, interests and everyday experiences as starting points for learning.",
      'A child interested in dinosaurs might explore books, visit a museum, draw fossils, research evolution or create a project. The parent acts as a facilitator, helping provide resources, opportunities and guidance rather than directing every lesson.',
      'Unschooling can offer children significant freedom and autonomy, but it still requires an engaged parent who observes, supports and creates opportunities for learning. Families can also combine child-led learning with more structured activities where appropriate.',
    ],
    'Unit Studies': [
      'Unit studies organise learning around one central topic and use it to explore several subjects at once. Instead of teaching each subject separately, children might study space through science, history, maths, reading, writing and art.',
      'For example, a unit on Ancient Egypt could include reading historical texts, mapping the Nile, exploring Egyptian mathematics, studying pyramids and creating an art project.',
      'Unit studies can make learning feel connected and purposeful, while allowing children of different ages to explore the same topic at an appropriate level. They work particularly well for families who enjoy projects, hands-on activities and learning together.',
    ],
    'Teaching vs Facilitating Learning': [
      'Teaching often means giving children information, explaining concepts and guiding them towards a particular answer. It can be structured and intentional, with the adult taking the lead in deciding what is taught and when.',
      'Facilitating learning is more about creating the conditions for children to discover, question and explore. Instead of always providing the answer, you might ask questions, provide resources or introduce an experience that encourages them to think for themselves.',
      'Homeschooling can use both approaches. Some subjects may benefit from direct teaching, while others can become opportunities for exploration and discovery. The key is knowing when to lead and when to step back.',
    ],
    'How Children Learn Best': [
      'Children learn best when they are curious, interested and actively involved. Learning is often more effective when children can ask questions, explore ideas, make mistakes and connect new information to things they already understand.',
      "Every child is different. Some may enjoy reading and discussion, while others learn through doing, creating, movement or real-world experiences. Paying attention to what captures your child's attention can help you find approaches that work naturally for them.",
      'The best learning environment is one where children feel safe to be curious. Rather than focusing only on completing lessons, give them opportunities to explore, ask “why?”, follow their interests and understand how what they are learning connects to the world around them.',
    ],
    'The Art of Asking Good Questions': [
      'Good questions can turn an ordinary activity into a learning opportunity. Instead of simply telling your child what something is, ask questions that encourage them to observe, think and explain their ideas. Try “What do you notice?” or “Why do you think that happened?”',
      'Open questions are especially useful because they do not always have one correct answer. Questions such as “What would happen if...?”, “How could we...?” or “What makes you think that?” encourage children to explore possibilities and explain their reasoning.',
      'You do not need to ask questions constantly. Give your child time to think, follow their answers with another question and be genuinely interested in their ideas. Sometimes, the best learning happens when you simply ask a question and let the conversation develop.',
    ],
    'How to Teach Without Giving Your Child the Answer': [
      'It can be tempting to give your child the answer when they are stuck, but sometimes the most valuable learning happens when they work it out themselves. Instead of solving the problem, offer a question, hint or resource that helps them take the next step.',
      'Try asking, “What do you already know?”, “What could you try?” or “Where could we find out?” You can break a difficult task into smaller steps without taking over, giving your child enough support to keep going while still doing the thinking themselves.',
      'The goal is not to leave your child struggling. Good facilitation means knowing when to step in and when to step back. When your child eventually reaches the answer themselves, they are not just learning the answer—they are developing confidence, problem-solving skills and independence.',
    ],
    'Reading Together': [
      'Reading together is more than simply listening to your child read. It can be a chance to explore stories, build vocabulary and talk about ideas. Take turns reading, pause to discuss what is happening and encourage your child to make predictions about what might happen next.',
      'You can ask simple questions such as “Why do you think they did that?” or “How would you feel in their situation?” For younger children, talk about the pictures and let them point out things they notice. There is no need to turn every book into a lesson.',
      'Most importantly, make reading enjoyable. Let your child choose books that interest them, revisit favourite stories and give them time to read independently too. A positive relationship with books can be just as valuable as the reading skills they develop.',
    ],
    'Teaching Writing at Home': [
      'Writing at home does not have to mean sitting down with a worksheet. Children can develop writing skills through things that have a real purpose: writing stories, keeping a journal, making lists, creating comics, sending letters or explaining something they have learned.',
      'Focus on ideas first, then help your child improve their writing. Ask what they want to say, who they are writing for and how they could make their meaning clearer. Encourage them to experiment with vocabulary and sentence structure rather than worrying about getting everything perfect immediately.',
      'Regular practice matters more than long writing sessions. Follow your child’s interests, celebrate their ideas and gradually introduce spelling, grammar, punctuation and structure. The aim is to help children see writing as a way to communicate, create and make their ideas understood.',
    ],
    'How to Build a Homeschool Routine': [
      'A good homeschool routine gives your child structure without making every day feel like school. Start with the essentials, such as reading, maths and other key subjects, then leave space for play, outdoor time, hobbies and following your child’s interests.',
      'You do not need to plan every minute. Some families work best with a simple morning routine, while others spread learning throughout the day. Think about when your child concentrates best and build your most focused activities around that time.',
      'Keep your routine flexible enough to change. A museum visit, rainy afternoon, family day out or unexpected interest can all become learning opportunities. The goal is to create a rhythm that works for your family, rather than trying to recreate a school timetable at home.',
    ],
    'Do You Need a Timetable?': [
      'You do not need a strict timetable to homeschool successfully. Some families enjoy having set times for maths, reading and other subjects, while others prefer a looser routine that changes from day to day.',
      'A timetable can provide structure and help children know what to expect, but it should work for your family rather than become a source of stress. You might simply have a morning routine, a list of things to complete each day or a weekly plan instead of scheduling every hour.',
      'The important thing is that your child has regular opportunities to learn. If a rigid timetable is not working, change it. Homeschooling gives you the flexibility to build a routine around your child’s needs, interests and natural rhythm.',
    ],
    'Planning a Week of Learning': [
      'Planning a week of homeschooling does not have to mean filling every hour. Start by choosing the key things you want your child to learn or practise, then spread those across the week. Include core subjects alongside reading, creative activities, outdoor time and experiences.',
      'Think about variety. A maths session might be followed by a nature walk, a science experiment or a trip to a museum. You can also leave some time unplanned so your child can follow an interest that comes up during the week.',
      'At the end of the week, take a few minutes to look back. What worked well? What did your child enjoy? What still needs attention? Use this to shape the following week rather than trying to create a perfect plan in advance.',
    ],
    'Planning a Term': [
      'Planning a homeschool term is about creating direction without planning every day in advance. Start by identifying the main subjects, topics or skills you would like your child to explore, then choose a few experiences, books and projects to support them.',
      'Think about the bigger picture. A topic such as Ancient Egypt could include history, reading, writing, art, geography and a museum visit. Connecting subjects around a shared theme can make learning feel more meaningful and easier to plan.',
      'Leave room for your plans to change. Your child may become fascinated by something unexpected or need more time with a particular topic. A good term plan provides a framework, not a fixed timetable, allowing you to follow your child’s interests while still making steady progress.',
    ],
    "Planning Around Your Child's Interests": [
      'Your child’s interests can be a powerful starting point for learning. If they love dinosaurs, for example, you can explore fossils in science, read dinosaur books, write a fact file, study prehistoric geography or visit a natural history museum.',
      'Following interests does not mean abandoning structure or core subjects. Instead, use what excites your child as a way into different areas of learning. An interest in cooking can involve maths, science, reading and practical skills, while a fascination with space can lead to physics, history, art and writing.',
      'Pay attention to the questions your child asks and the subjects they return to repeatedly. These interests can help you decide what to explore next, making learning feel purposeful, relevant and driven by genuine curiosity.',
    ],
    'How to Plan Without Overplanning': [
      'Planning can give your homeschool direction, but too much planning can leave little room for curiosity. Start with a simple goal for the week rather than deciding exactly what your child will do every hour. Choose a few key subjects, activities or experiences and let the rest develop naturally.',
      'Avoid planning every lesson in detail before you know how your child will respond. A book, experiment or museum visit might lead somewhere completely unexpected—and that can become valuable learning. Leave gaps in your plan for questions, interests and opportunities that appear along the way.',
      'Think of your plan as a guide rather than a contract. At the end of each week, look at what your child learned, what they enjoyed and what needs more time. Then adjust your next plan accordingly. Good planning should make homeschooling easier, not make you feel like you are constantly trying to keep up.',
    ],
    'Understanding Your Child as a Learner': [
      'Every child approaches learning differently. Some enjoy structure and clear instructions, while others prefer to explore, ask questions and discover things independently. Pay attention to when your child becomes engaged, what they find frustrating and which activities naturally hold their attention.',
      'Look beyond what they are learning and notice how they learn. Do they remember something better after doing it, discussing it, seeing it or reading about it? These observations can help you choose activities and resources that make learning more accessible and enjoyable.',
      'Understanding your child does not mean putting them into a fixed “learning style” category. Children can learn in many different ways depending on the subject and situation. The goal is to stay curious about how your child learns best and adapt your approach as they grow.',
    ],
    'Building Independence': [
      'Homeschooling gives children many opportunities to become more independent learners. Start by giving them small responsibilities, such as choosing a book, organising their materials or deciding how they want to complete a task.',
      'As their confidence grows, gradually step back. Instead of reminding them what to do at every stage, encourage them to make a plan, find resources and check their own work. It is okay if they make mistakes—learning how to recover from them is part of becoming independent.',
      'Independence does not mean leaving your child to figure everything out alone. Be available to guide and support them when needed, while giving them increasing ownership of their learning. Over time, the aim is for your child to become confident in asking questions, solving problems and taking responsibility for their progress.',
    ],
    'Helping Your Child Develop Confidence': [
      'Confidence grows when children feel capable, supported and trusted. Give your child opportunities to try things for themselves, make decisions and tackle challenges that are difficult but achievable. Focus on their effort and progress rather than expecting everything to be perfect.',
      'Be careful not to step in too quickly when something goes wrong. Encourage your child to think about what they could try next and remind them that mistakes are a normal part of learning. Celebrate persistence, curiosity and improvement as much as correct answers.',
      'Most importantly, let your child know that their ideas matter. Listen to their questions, take their interests seriously and give them space to share their thinking. When children feel safe to make mistakes and express themselves, they can gradually develop the confidence to take on new challenges.',
    ],
    'When Learning Feels Difficult': [
      'Every child will experience moments when learning feels difficult. When this happens, resist the urge to simply push through. Take a step back and ask what is making the task challenging. Your child may need more time, a different explanation or a break before trying again.',
      'Break difficult tasks into smaller steps and celebrate progress along the way. You might use a practical activity, a different book or an everyday example to help make an idea easier to understand. Sometimes changing the approach is more effective than repeating the same explanation.',
      'Most importantly, reassure your child that finding something difficult does not mean they cannot learn it. Encourage questions, mistakes and persistence. The aim is not to remove every challenge, but to help your child develop the confidence and strategies to work through them.',
    ],
    'Avoiding Homeschool Burnout': [
      'Homeschooling can be rewarding, but trying to do everything perfectly can quickly become exhausting. You do not need to plan every lesson, visit every experience or cover every subject every day. Focus on what matters most and give yourself permission to keep things simple.',
      'Build regular breaks into your routine—for both you and your child. Mix structured learning with reading, outdoor time, independent activities and free play. If a day does not go to plan, it is okay to stop, reset and try again tomorrow.',
      'Pay attention to your own energy as well as your child’s. If homeschooling is becoming a constant source of stress, look at what you can simplify, share or change. A sustainable routine that works for your family is far more valuable than a perfect one that leaves everyone exhausted.',
    ],
    'Creating a Healthy Balance': [
      'A healthy homeschool routine is about more than completing lessons. Children need a balance of focused learning, movement, outdoor time, creativity, rest and opportunities to play. Try to create a day that includes different types of activity rather than sitting at a desk for long periods.',
      'Balance also means making space for your child’s interests and independence. Not every valuable learning experience needs to be planned or measured. Cooking together, visiting a museum, exploring nature or talking about something they are curious about can all contribute to learning.',
      'Remember that your family’s balance may look different from another homeschool. Some days will be busy and productive, while others may be slower. The goal is to create a rhythm that supports learning while leaving enough time for your child—and you—to relax, explore and enjoy family life.',
    ],
    'Do Homeschooled Children Need Socialisation?': [
      'Yes. Children need regular opportunities to build friendships, communicate with others and develop social skills, but this does not have to happen in a traditional school environment. Homeschooling can provide social experiences through clubs, sports, classes, community groups, family activities and meeting other home-educating families.',
      'Socialisation is about more than simply spending time with other children. Give your child opportunities to cooperate, solve problems, share ideas, handle disagreements and interact with people of different ages. Real-world experiences can provide plenty of opportunities to practise these skills.',
      'The key is finding social opportunities that suit your child. Some children enjoy large groups, while others feel more comfortable with one or two friends. A healthy homeschool routine can combine learning at home with regular opportunities to connect, play and learn alongside others.',
    ],
    'Building Friendships Outside School': [
      'Homeschooling does not mean your child has to miss out on friendships. Look for regular activities where children can meet repeatedly, such as sports clubs, creative classes, community groups, homeschool meetups or shared learning experiences.',
      'Friendships often grow through shared interests and repeated contact. Encourage your child to spend time with children they enjoy being around, rather than focusing on having a large number of friends. A museum visit, football session or art workshop can become the starting point for a lasting friendship.',
      'You can also help friendships develop outside organised activities. Arrange playdates, park trips or shared projects with other families. Give children space to play and talk independently while being available when they need support. Building friendships takes time, so focus on creating regular opportunities for connection.',
    ],
    'Finding Your Homeschool Community': [
      'A supportive homeschool community can make learning feel less isolated and give both you and your child opportunities to connect with others. Start by looking for local groups, meetups, clubs, classes, sports or families with similar interests.',
      'You do not need to find one perfect community. You might meet one family through a nature group, another through a museum visit and others through a regular activity. Over time, these connections can become a valuable network for sharing ideas, experiences and friendship.',
      'Take your time finding people who feel right for your family. A good community should feel welcoming and supportive, while giving children opportunities to learn, play and build relationships. Even a few regular connections can make a meaningful difference.',
    ],
    'How to Make Homeschool Friends': [
      'Making friends through homeschooling often starts with simply showing up. Look for local meetups, sports clubs, workshops, museum activities, outdoor groups or other regular activities where you and your child can meet the same families more than once.',
      'Encourage your child to talk to others through shared interests. A favourite game, book, sport or activity can make it easier to start a conversation. You can also introduce yourself to other parents and suggest meeting again at a park, activity or learning experience.',
      'Friendships take time, so do not worry if connections do not happen immediately. Focus on creating regular opportunities to meet people your child enjoys being around. With time, familiar faces can become friendships, and friendships can grow into a wider homeschool community.',
    ],
    'Learning With Other Families': [
      'Learning with other families can bring energy, variety and social connection to homeschooling. You might meet another family for a nature walk, work together on a project, visit a museum or organise a shared activity around a particular subject.',
      'Children can learn a great deal from one another. They can explain ideas, ask questions, solve problems together and see different ways of approaching the same task. Mixed-age groups can also create opportunities for older and younger children to learn from each other.',
      'You do not need to organise a large group. Even one or two families can create valuable shared learning experiences. Keep activities simple, choose something everyone can enjoy and allow plenty of time for children to explore, talk and play together.',
    ],
    'Organising a Homeschool Meetup': [
      'A homeschool meetup does not need to be complicated. Choose a simple activity, a convenient location and a clear time. A park, museum, library or outdoor space can work well, especially when children have room to explore and parents can chat.',
      'Keep the first meetup relaxed. You could organise a nature walk, picnic, scavenger hunt, creative activity or visit to a local attraction. Give children opportunities to interact naturally rather than planning every minute of the session.',
      'Start small and build from there. A few families who enjoy spending time together can become a regular group. Agree on basic expectations around supervision, communication and behaviour, and make sure parents remain responsible for their own children throughout the meetup.',
    ],
    'How Do I Know If My Child Is Learning?': [
      'Learning does not always look like completing a worksheet or getting the right answer. Look for signs that your child is becoming more curious, remembering ideas, asking questions, explaining their thinking or applying something they have learned in a new situation.',
      'You can also notice progress through everyday activities. Can they read something they once struggled with? Explain a scientific idea? Solve a problem independently? Use new vocabulary in conversation? These small changes can show meaningful learning even when there is no test or finished piece of work.',
      'Keep simple notes, photos or examples of your child’s work so you can look back over time. If progress seems slow, use what you observe to decide what to revisit or approach differently. You do not need to measure everything—the goal is to understand how your child is developing and where they may need support.',
    ],
    'Do You Need Tests?': [
      'Tests are not essential for every homeschool family. They can be useful for checking what your child remembers, identifying gaps in understanding or helping them practise working under timed conditions, but they are only one way to assess learning.',
      'You can also assess progress through conversations, projects, written work, practical activities and simply observing how your child applies what they have learned. Asking your child to explain an idea in their own words can often tell you more than a score on a test.',
      'If your child is preparing for formal qualifications such as GCSEs, tests and practice papers can become more important. For everyday homeschooling, focus on understanding and progress rather than testing for its own sake. Use assessment as a tool to guide learning, not as the definition of success.',
    ],
    'Assessment Without Exams': [
      'You can assess your child’s learning without relying on exams. Pay attention to how they explain ideas, solve problems, complete projects and use what they have learned in everyday situations. Their questions and conversations can also reveal how their understanding is developing.',
      'Keep examples of their work over time, such as writing, drawings, projects, photographs or completed activities. Looking back at earlier work can help you see progress that may not be obvious from day to day.',
      'You can also ask your child to teach you something they have learned. If they can explain an idea clearly, give examples or apply it in a new situation, that is a strong sign of understanding. Assessment can be a natural part of learning rather than a separate exam.',
    ],
    'Keeping a Learning Portfolio': [
      'A learning portfolio is a collection of your child’s work and experiences that shows how they are developing over time. It might include writing, drawings, photographs, projects, reading lists, certificates or notes about interesting conversations and activities.',
      'You do not need to save everything. Choose examples that show progress, new skills, personal interests or something your child is particularly proud of. A museum visit, science experiment or outdoor project can be recorded with a photograph and a few notes.',
      'Looking back through the portfolio can help you see how far your child has come and decide what to explore next. It can also give your child a sense of achievement by showing them their own progress over time.',
    ],
    "Recording Your Child's Progress": [
      'Recording progress does not have to mean completing detailed reports every week. Keep simple notes about what your child has learned, skills they are developing, books they have read and subjects or interests they have explored.',
      'Save useful examples of their work, such as writing, drawings, projects or photographs of practical activities. You might also record a short note after a museum visit, experiment or conversation about something they have discovered.',
      'Review your notes regularly to spot progress and identify areas that may need more attention. Over time, these records can give you a clear picture of your child’s learning journey and help you plan what to explore next.',
    ],
    'Using Projects as Evidence of Learning': [
      'Projects can show learning in ways that worksheets and tests cannot. A project might be a model, presentation, investigation, piece of writing, artwork or practical challenge. Look at what your child has learned, the decisions they made and how they solved problems along the way.',
      'You do not need to assess every project formally. Keep examples that show new skills, deeper understanding or progress over time. A photograph of a finished project, along with a few notes about what your child did and learned, can be enough.',
      'Projects can also bring several subjects together. Building a model bridge might involve maths, science, design and writing, while creating a historical presentation could involve research, reading and communication. This makes projects useful evidence of both knowledge and practical skills.',
    ],
    'Home Education in England: What Parents Need to Know': [
      'In England, parents have a legal duty to ensure their child receives a suitable full-time education, but this does not have to take place at school. You can choose to educate your child at home, and you do not have to follow the National Curriculum or copy a school timetable.',
      'Your approach can be flexible, but the education should be suitable for your child’s age, ability, aptitude and any special educational needs they may have. You can use books, projects, online resources, tutors, community activities and real-world experiences as part of their education.',
      'If your child is registered at a mainstream school, you will normally need to notify the school in writing that you are educating them at home. Councils can make enquiries about whether a suitable education is being provided. Requirements can differ in specific circumstances, so check the latest guidance for your local authority before making changes.',
    ],
    'Your Legal Responsibilities': [
      'In England, parents are responsible for ensuring their child receives a suitable full-time education, either at school or otherwise. Home education does not have to follow the National Curriculum, and parents generally have flexibility over how, where and when learning takes place.',
      'If your child is registered at a school, you may need to notify the school if you decide to educate them at home. The local authority can make enquiries if it appears that a child may not be receiving a suitable education, although this does not mean every home-educating family is routinely inspected.',
      'It is important to understand the rules that apply to your circumstances, particularly if your child has an Education, Health and Care Plan or attends a special school. Requirements can vary, so check current government guidance and your local authority’s information before making decisions about home education.',
    ],
    'Do You Have to Follow the National Curriculum?': [
      'No. In England, home educators generally do not have to follow the National Curriculum. You can choose what your child learns, how you teach it and how you organise your days, provided the education you provide is suitable, efficient and full-time.',
      'This gives you the freedom to build learning around your child. You might use school-style textbooks, follow a particular educational philosophy, create your own curriculum or combine different approaches. Trips, projects, practical activities and everyday experiences can all form part of your child’s education.',
      'You may still choose to use the National Curriculum as a guide, especially if you want to keep track of age-related subjects or prepare your child for future qualifications. The important thing is not following a particular curriculum, but providing an education that meets your child’s needs.',
    ],
    'Leaving School to Home Educate': [
      'If you decide to home educate your child in England, the process depends on their current school situation. For a child attending a mainstream school, parents can generally withdraw them from the school and take responsibility for providing their education at home.',
      'Before making the change, think about what your first few weeks will look like. You do not need to recreate school at home immediately. Give your child time to adjust, talk about what they enjoy learning and begin building a simple routine that works for your family.',
      'If your child attends a special school, or has an Education, Health and Care Plan (EHCP), different rules can apply. Check with your local authority and the latest government guidance before withdrawing your child, so you understand the requirements that apply to your circumstances.',
    ],
    'Working With Your Local Council': [
      'Your local council has a role in making enquiries where there are concerns that a child may not be receiving a suitable education. This does not mean that every home educator is routinely monitored or required to submit regular work for inspection.',
      'If the council contacts you, respond clearly and keep records that show what your child is learning. You might share an outline of your approach, examples of work or other evidence of your child’s progress, depending on what is requested.',
      'Try to keep communication constructive and focused on your child’s education. If you are unsure about a request or your legal responsibilities, check the latest government guidance or seek independent advice. Requirements can vary depending on your circumstances, so avoid assuming that another family’s experience will be the same as yours.',
    ],
    'Home Education & SEN': [
      'Home education can be adapted around a child’s individual needs, which can allow families to choose flexible routines, environments and learning approaches. You can adjust the pace of learning, use different resources and build education around your child’s strengths and interests.',
      'If your child has special educational needs (SEN), think about what helps them engage and communicate. This might include shorter learning sessions, sensory breaks, practical activities, visual resources or additional support from specialists. There is no single approach that works for every child.',
      'If your child has an Education, Health and Care Plan (EHCP), or attends a special school, additional legal considerations can apply when moving to home education. Before making a decision, speak to your local authority and check the current guidance so you understand how home education may affect the support your child receives.',
    ],
    'Home Education & GCSEs': [
      'Homeschooled children can work towards GCSEs, but the route can look different from school. You can choose subjects, use tutors or online courses and organise study around your child. You do not have to teach the GCSE content yourself.',
      'The main consideration is how your child will take the exams. GCSEs are normally sat through an approved exam centre, and some subjects include coursework, practical assessments or spoken components that require specific arrangements. It is important to research these requirements well in advance.',
      'Start by choosing subjects and checking the relevant exam boards, specifications and assessment requirements. Then work backwards from the exam dates to plan your study. Giving yourself plenty of time to find an exam centre and understand the requirements can make the process much smoother.',
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showScreenInfoOnFirstVisit(context, ScreenInfoType.community);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_bottomIndex == 1) {
      return ExperiencesScreen(
        onTabSelected: (index) => setState(() => _bottomIndex = index),
      );
    }
    if (_bottomIndex == 2) {
      return TimetableScreen(
        onTabSelected: (index) => setState(() => _bottomIndex = index),
      );
    }
    if (_bottomIndex == 3) {
      return ResourcesScreen(
        onTabSelected: (index) => setState(() => _bottomIndex = index),
      );
    }
    if (_bottomIndex == 4) {
      return ProfileScreen(
        onTabSelected: (index) => setState(() => _bottomIndex = index),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1, color: Color(0xFFEAEAEA)),
              Expanded(child: _buildFeed()),
              _buildFeedFilter(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 18, 14),
        child: Row(
          children: [
            Text(
              'Home',
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            ScreenInfoButton(
              onPressed: () =>
                  showScreenInfoPopup(context, ScreenInfoType.community),
            ),
            const SizedBox(width: 10),
            Material(
              color: Colors.white,
              shape: CircleBorder(
                side: BorderSide(color: const Color(0xFFE5E5E5)),
              ),
              child: InkWell(
                onTap: () => showCommunitySettingsPopup(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Icon(Icons.tune_rounded, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: _green,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => showHomePostPopup(context),
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: Image(
                      image: AssetImage('assets/latestmessagevector.png'),
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed() {
    if (_feedView == _FeedView.learn) return _buildLearnView();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const _NoMatchingCommunity();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData && !profileSnapshot.hasError) {
          return const Center(
            child: CircularProgressIndicator(color: _green, strokeWidth: 2),
          );
        }

        final preferences = profileSnapshot.data?.data() ?? const {};
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('posts').snapshots(),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.hasError) {
              return _feedView == _FeedView.replies
                  ? const _EmptyReplies()
                  : const _NoMatchingCommunity();
            }

            if (!postsSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _green, strokeWidth: 2),
              );
            }

            final posts = postsSnapshot.data!.docs.toList()
              ..sort(
                (a, b) => _postDate(b.data()).compareTo(_postDate(a.data())),
              );
            if (_feedView == _FeedView.replies) {
              final replyPosts = posts.where(_isReplyForCurrentUser).toList();
              return replyPosts.isEmpty
                  ? const _EmptyReplies()
                  : _buildReplyThreads(replyPosts);
            }

            if (_feedView == _FeedView.connections) {
              return _buildConnectionsList(user.uid);
            }

            final visiblePosts = posts
                .where(
                  (post) =>
                      _matchesCommunity(post.data(), preferences, user.uid),
                )
                .toList();

            if (visiblePosts.isEmpty) {
              return const _NoMatchingCommunity();
            }

            return _buildPostList(
              visiblePosts
                  .map(
                    (post) => <String, dynamic>{...post.data(), '_id': post.id},
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildLearnView() {
    final topics = switch (_learnCategory) {
      'Getting started' => _learnTopics,
      'Learning styles' => _learningStyleTopics,
      'Teaching' => _teachingTopics,
      'Planning' => _planningTopics,
      'Wellbeing' => _wellbeingTopics,
      'Community' => _communityLearnTopics,
      'Progress' => _progressTopics,
      'Legal' => _legalTopics,
      _ => const <String>[],
    };
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SizedBox(
          height: 58,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            scrollDirection: Axis.horizontal,
            itemCount: _learnCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _learnCategories[index];
              final selected = category == _learnCategory;
              return ActionChip(
                onPressed: () => setState(() => _learnCategory = category),
                label: Text(category),
                backgroundColor: const Color(0xFFF6FBF7),
                side: BorderSide(
                  color: selected ? _green : Colors.transparent,
                  width: 1.5,
                ),
                shape: const StadiumBorder(),
                labelStyle: GoogleFonts.lato(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                visualDensity: VisualDensity.compact,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              width: double.infinity,
              height: 158,
              child: switch (_learnCategory) {
                'Getting started' => const Image(
                  image: AssetImage('assets/screensIcons/ExprienceIcon.png'),
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
                'Learning styles' => const Image(
                  image: AssetImage('assets/new_updated_image.jpeg'),
                  fit: BoxFit.cover,
                ),
                _ => null,
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            children: topics
                .map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                        side: const BorderSide(color: Color(0xFFE3E3E3)),
                      ),
                      child: InkWell(
                        onTap: () => _showLearnArticle(topic),
                        borderRadius: BorderRadius.circular(9),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                topic,
                                style: GoogleFonts.lato(
                                  color: const Color(0xFF171717),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  void _showLearnArticle(String topic) {
    final paragraphs = _learnArticles[topic];
    if (paragraphs == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black45,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.80,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 27, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _learningStyleTopics.contains(topic)
                        ? 'Learning styles'
                        : _teachingTopics.contains(topic)
                        ? 'Teaching'
                        : _planningTopics.contains(topic)
                        ? 'Planning'
                        : _wellbeingTopics.contains(topic)
                        ? 'Wellbeing'
                        : _communityLearnTopics.contains(topic)
                        ? 'Community'
                        : _progressTopics.contains(topic)
                        ? 'Progress'
                        : _legalTopics.contains(topic)
                        ? 'Legal'
                        : 'Getting started',
                    style: GoogleFonts.lato(
                      color: const Color(0xFF303030),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topic,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF171717),
                      fontSize: 24,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '30 sec read',
                    style: GoogleFonts.lato(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: paragraphs
                            .map(
                              (paragraph) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: Text(
                                  paragraph,
                                  style: GoogleFonts.lato(
                                    color: const Color(0xFF2A2A2A),
                                    fontSize: 14,
                                    height: 1.4,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyThreads(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> posts,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      itemCount: posts.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 28, color: Color(0xFFE4E4E4)),
      itemBuilder: (context, index) =>
          _ReplyThread(post: posts[index].data(), postId: posts[index].id),
    );
  }

  static bool _matchesCommunity(
    Map<String, dynamic> post,
    Map<String, dynamic> preferences,
    String? currentUserId,
  ) {
    if (currentUserId != null && post['authorId'] == currentUserId) return true;

    final approach = preferences['homeschoolApproach'];
    final subjects = _stringList(preferences['subjects']).toSet();
    if ((approach == null || approach == '') && subjects.isEmpty) return true;

    final sameApproach =
        approach is String &&
        approach.isNotEmpty &&
        post['homeschoolApproach'] == approach;
    final postSubjects = _stringList(post['subjects']);
    final sharedSubject = postSubjects.any(subjects.contains);

    final usesLocation = preferences['locationSharingEnabled'] == true;
    final inDiscoveryRegion = !usesLocation || post['communityRegion'] == 'UK';
    return inDiscoveryRegion && (sameApproach || sharedSubject);
  }

  Widget _buildPostList(List<Map<String, dynamic>> posts) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, index) => _PostCard(post: posts[index]),
    );
  }

  Widget _buildConnectionsList(String userId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('parents')
          .snapshots(),
      builder: (context, connectionsSnapshot) {
        if (connectionsSnapshot.hasError) {
          return const _NoConnectionPosts();
        }
        if (!connectionsSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: _green, strokeWidth: 2),
          );
        }

        final connections = connectionsSnapshot.data!.docs;
        if (connections.isEmpty) return const _NoConnectionPosts();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          itemCount: connections.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final connection = connections[index];
            final data = connection.data();
            final storedName = data['name'];
            final name = storedName is String && storedName.trim().isNotEmpty
                ? storedName.trim()
                : 'Connection';
            return _HomeConnectionTile(
              currentUserId: userId,
              connectionId: connection.id,
              name: name,
              onMessage: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ConversationScreen(
                    connectionId: connection.id,
                    connectionName: name,
                  ),
                ),
              ),
              onFlag: () => _flagConnection(context, connection.id, name),
              onRemove: () =>
                  _removeConnection(context, userId, connection.id, name),
            );
          },
        );
      },
    );
  }

  Future<void> _flagConnection(
    BuildContext context,
    String connectionId,
    String connectionName,
  ) async {
    final confirmed = await _confirmConnectionAction(
      context,
      title: 'Flag $connectionName?',
      message:
          'This will privately report this connection to the Classmates moderation team.',
      actionLabel: 'Flag',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await FirebaseFirestore.instance.collection('connectionReports').add({
        'reportedUserId': connectionId,
        'reportedBy': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      showMessagePopup(context, message: 'Connection flagged for review.');
    } catch (_) {
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: 'Could not flag this connection.',
        type: MessageType.error,
      );
    }
  }

  Future<void> _removeConnection(
    BuildContext context,
    String userId,
    String connectionId,
    String connectionName,
  ) async {
    final confirmed = await _confirmConnectionAction(
      context,
      title: 'Remove $connectionName?',
      message: 'They will no longer appear in your Connections list.',
      actionLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('parents')
          .doc(connectionId)
          .delete();
      if (!context.mounted) return;
      showMessagePopup(context, message: 'Connection removed.');
    } catch (_) {
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: 'Could not remove this connection.',
        type: MessageType.error,
      );
    }
  }

  Future<bool> _confirmConnectionAction(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: destructive
                        ? const Color(0xFFFF444B)
                        : const Color(0xFF0DA64A),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  static DateTime _postDate(Map<String, dynamic> post) {
    final value = post['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isReplyForCurrentUser(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    final post = document.data();
    final replyUsers = _stringList(post['replyToUserIds']);
    final mentionedUsers = _stringList(post['mentionedUserIds']);
    final replyCount = post['replyCount'] is num
        ? (post['replyCount'] as num).toInt()
        : 0;

    return replyUsers.contains(userId) ||
        mentionedUsers.contains(userId) ||
        (post['authorId'] == userId && replyCount > 0);
  }

  static List<String> _stringList(Object? value) {
    return value is Iterable ? value.whereType<String>().toList() : const [];
  }

  Widget _buildFeedFilter() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FilterChip(
            label: 'Community',
            selected: _feedView == _FeedView.all,
            onTap: () => setState(() => _feedView = _FeedView.all),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Connections',
            selected: _feedView == _FeedView.connections,
            onTap: () => setState(() => _feedView = _FeedView.connections),
          ),
          const SizedBox(width: 12),
          _FilterChip(
            label: 'Learn',
            selected: _feedView == _FeedView.learn,
            onTap: () => setState(() => _feedView = _FeedView.learn),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.waving_hand_outlined, 'Experiences'),
      (Icons.calendar_month_outlined, 'Timetable'),
      (Icons.business_center_outlined, 'Resources'),
      (Icons.person_outline_rounded, 'Profile'),
    ];

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: SizedBox(
          height: 58,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == _bottomIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _bottomIndex = index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      if (index == 0)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/Home_active.png'
                                : 'assets/HomeIcon.png',
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: const Color(0xFF111111),
                          colorBlendMode: BlendMode.srcIn,
                        )
                      else if (index == 1)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/experienceIconSelected.png'
                                : 'assets/experienceIconUpdated.png',
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: const Color(0xFF111111),
                          colorBlendMode: BlendMode.srcIn,
                        )
                      else if (index == 2)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/calenderIconselected.png'
                                : 'assets/calenderIcon.png',
                          ),
                          width: 18,
                          height: 20,
                          fit: BoxFit.contain,
                        )
                      else if (index == 3)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/Resources_Active.png'
                                : 'assets/resorcessIcon.png',
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: const Color(0xFF111111),
                          colorBlendMode: BlendMode.srcIn,
                        )
                      else if (index == 4)
                        Image(
                          image: AssetImage(
                            selected
                                ? 'assets/Profile_Active.png'
                                : 'assets/profileIcon.png',
                          ),
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                          color: const Color(0xFF111111),
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF111111),
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0DA64A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF0DA64A) : const Color(0xFFD9D9D9),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: selected ? Colors.white : const Color(0xFF171717),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyReplies extends StatelessWidget {
  const _EmptyReplies();

  @override
  Widget build(BuildContext context) {
    return const _FeedMessage(
      title: 'No replies yet',
      description:
          'Replies to your posts and mentions\nfrom other parents will appear here.',
      actionText:
          'Join the conversation by asking a\nquestion or replying to a post.',
    );
  }
}

class _HomeConnectionTile extends StatelessWidget {
  const _HomeConnectionTile({
    required this.currentUserId,
    required this.connectionId,
    required this.name,
    required this.onMessage,
    required this.onFlag,
    required this.onRemove,
  });

  final String currentUserId;
  final String connectionId;
  final String name;
  final VoidCallback onMessage;
  final VoidCallback onFlag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ids = [currentUserId, connectionId]..sort();
    final threadId = '${ids.first}_${ids.last}';
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(threadId)
          .snapshots(),
      builder: (context, snapshot) {
        final conversation = snapshot.data?.data();
        final storedMessage = conversation?['lastMessage'];
        final lastMessage = storedMessage is String && storedMessage.isNotEmpty
            ? storedMessage
            : 'No messages yet';
        final unreadFor = conversation?['unreadFor'];
        final hasUnread =
            unreadFor is List && unreadFor.contains(currentUserId);
        final lastMessageAt = conversation?['lastMessageAt'];
        return _buildTile(
          lastMessage: lastMessage,
          lastMessageAt: lastMessageAt is Timestamp
              ? lastMessageAt.toDate()
              : null,
          hasUnread: hasUnread,
        );
      },
    );
  }

  Widget _buildTile({
    required String lastMessage,
    required DateTime? lastMessageAt,
    required bool hasUnread,
  }) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return _SwipeableConnection(
      onFlag: onFlag,
      onRemove: onRemove,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onMessage,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFEAF4FF),
                  child: Text(
                    initials.isEmpty ? '?' : initials,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF3478C9),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF171717),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lato(
                          color: const Color(0xFF737373),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (lastMessageAt != null || hasUnread)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (lastMessageAt != null)
                        Text(
                          _messageTime(lastMessageAt),
                          style: GoogleFonts.lato(
                            color: hasUnread
                                ? const Color(0xFF0DA64A)
                                : const Color(0xFF777777),
                            fontSize: 11,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      if (hasUnread) ...[
                        const SizedBox(height: 5),
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0DA64A),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '1',
                            style: GoogleFonts.lato(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _messageTime(DateTime value) {
    final now = DateTime.now();
    final date = DateUtils.dateOnly(value);
    final today = DateUtils.dateOnly(now);
    if (date == today) {
      return '${value.hour.toString().padLeft(2, '0')}:'
          '${value.minute.toString().padLeft(2, '0')}';
    }
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${value.day}/${value.month}/${value.year}';
  }
}

class _SwipeableConnection extends StatefulWidget {
  const _SwipeableConnection({
    required this.child,
    required this.onFlag,
    required this.onRemove,
  });

  final Widget child;
  final VoidCallback onFlag;
  final VoidCallback onRemove;

  @override
  State<_SwipeableConnection> createState() => _SwipeableConnectionState();
}

class _SwipeableConnectionState extends State<_SwipeableConnection> {
  static const _actionsWidth = 140.0;
  double _offset = 0;

  void _run(VoidCallback action) {
    setState(() => _offset = 0);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          SizedBox(
            width: _actionsWidth,
            height: 72,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(
                children: [
                  _SwipeAction(
                    icon: Icons.error_outline_rounded,
                    label: 'Flag',
                    backgroundColor: const Color(0xFFA9A9A9),
                    foregroundColor: Colors.white,
                    onTap: () => _run(widget.onFlag),
                  ),
                  const SizedBox(width: 12),
                  _SwipeAction(
                    icon: Icons.person_remove_outlined,
                    label: 'Remove',
                    backgroundColor: const Color(0xFFFF444B),
                    foregroundColor: Colors.white,
                    onTap: () => _run(widget.onRemove),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) => setState(
              () => _offset = (_offset + details.delta.dx).clamp(
                -_actionsWidth,
                0,
              ),
            ),
            onHorizontalDragEnd: (details) {
              final open =
                  _offset.abs() > _actionsWidth / 3 ||
                  (details.primaryVelocity ?? 0) < -250;
              setState(() => _offset = open ? -_actionsWidth : 0);
            },
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: ColoredBox(color: Colors.white, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoConnectionPosts extends StatelessWidget {
  const _NoConnectionPosts();

  @override
  Widget build(BuildContext context) {
    return const _FeedMessage(
      title: 'Your connections',
      description:
          'See the parents and carers you’ve connected with and message them directly.',
    );
  }
}

class _NoMatchingCommunity extends StatelessWidget {
  const _NoMatchingCommunity();

  @override
  Widget build(BuildContext context) {
    return _FeedMessage(
      title: 'No community posts yet',
      description:
          'Your community feed will appear here\nas parents start sharing.',
      actionText: 'Ask a question, share an experience,\nor say hello.',
      onActionTap: () => showHomePostPopup(context),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.title,
    required this.description,
    this.actionText,
    this.onActionTap,
  });

  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: const Color(0xFF171717),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                color: const Color(0xFF333333),
                fontSize: 16,
                height: 1.35,
              ),
            ),
            if (actionText case final text?) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onActionTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF0DA64A),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReplyThread extends StatelessWidget {
  const _ReplyThread({required this.post, required this.postId});

  final Map<String, dynamic> post;
  final String postId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('replies')
          .snapshots(),
      builder: (context, snapshot) {
        final liveReplies = <Map<String, dynamic>>[
          ...?snapshot.data?.docs.map((document) => document.data()),
        ];
        liveReplies.sort((a, b) => _replyDate(a).compareTo(_replyDate(b)));
        return _buildThread(liveReplies);
      },
    );
  }

  Widget _buildThread(List<Map<String, dynamic>> threadReplies) {
    final original = _firstText(post, ['content', 'text', 'body']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFF6F6F6),
          child: Text(
            original,
            style: GoogleFonts.lato(
              color: const Color(0xFF9A9A9A),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (threadReplies.isEmpty)
          Text(
            'Waiting for replies...',
            style: GoogleFonts.lato(
              color: const Color(0xFF8A8A8A),
              fontSize: 14,
            ),
          )
        else
          ...threadReplies.map(_buildReply),
      ],
    );
  }

  Widget _buildReply(Map<String, dynamic> reply) {
    final author = _firstText(reply, ['authorName', 'userName', 'name']);
    final body = _firstText(reply, [
      'content',
      'text',
      'body',
    ]).replaceFirst(RegExp(r'^@\S+\s*'), '').trim();
    final initials = author
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFFEAF4FF),
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: GoogleFonts.lato(
                    color: const Color(0xFF3478C9),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.isEmpty ? 'Community member' : author,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF282828),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _timeAgo(reply['createdAt']),
                    style: GoogleFonts.lato(
                      color: const Color(0xFF8A8A8A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            body,
            style: GoogleFonts.lato(
              color: const Color(0xFF333333),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _replyDate(Map<String, dynamic> reply) {
    final value = reply['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _timeAgo(Object? value) {
    final date = value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : null;
    if (date == null) return 'Just now';
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays}d ago';
  }

  static String _firstText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Map<String, dynamic> post;

  Future<void> _deletePost(BuildContext context) async {
    final postId = post['_id'] as String?;
    if (postId == null) return;
    final overlay = Overlay.of(context, rootOverlay: true);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete post?',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This post will be permanently deleted.',
          style: GoogleFonts.lato(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF444B),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      if (!overlay.mounted) return;
      showMessagePopupInOverlay(overlay, message: 'Post deleted successfully.');
    } on FirebaseException {
      if (!context.mounted) return;
      showMessagePopup(
        context,
        message: 'Could not delete this post.',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = _firstText(post, ['authorName', 'userName', 'name']);
    final body = _firstText(post, ['content', 'text', 'body']);
    final isOwner = post['authorId'] == FirebaseAuth.instance.currentUser?.uid;
    final initials = author
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    final postContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFEAF4FF),
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: GoogleFonts.lato(
                  color: const Color(0xFF3478C9),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author.isEmpty ? 'Community member' : author,
                    style: GoogleFonts.lato(
                      color: const Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeAgo(post['createdAt']),
                    style: GoogleFonts.lato(
                      color: const Color(0xFF8A8A8A),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 9),
          Text(
            body,
            style: GoogleFonts.lato(
              color: const Color(0xFF444444),
              fontSize: 15,
              height: 1.42,
            ),
          ),
        ],
      ],
    );

    final postId = post['_id'] as String?;
    return _SwipeablePost(
      onReport: () => showReportPostPopup(context, postId: postId),
      onReply: () =>
          showReplyPostPopup(context, postContent: body, postId: postId),
      onDelete: isOwner ? () => _deletePost(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          postContent,
          if (postId != null) _PublicPostReplies(postId: postId),
        ],
      ),
    );
  }

  static String _timeAgo(Object? value) {
    final date = value is Timestamp
        ? value.toDate()
        : value is DateTime
        ? value
        : null;
    if (date == null) return 'Just now';

    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    }
    return '${difference.inDays}d ago';
  }

  static String _firstText(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }
}

class _PublicPostReplies extends StatefulWidget {
  const _PublicPostReplies({required this.postId});

  final String postId;

  @override
  State<_PublicPostReplies> createState() => _PublicPostRepliesState();
}

class _PublicPostRepliesState extends State<_PublicPostReplies> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('replies')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final replies = snapshot.data!.docs.map((doc) => doc.data()).toList()
          ..sort((a, b) => _date(a).compareTo(_date(b)));
        final collapsible = replies.length >= 4;

        if (collapsible && !_expanded) {
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _RepliesToggle(
              label: 'View ${replies.length} replies',
              onTap: () => setState(() => _expanded = true),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${replies.length} ${replies.length == 1 ? 'Reply' : 'Replies'}',
                style: GoogleFonts.lato(
                  color: const Color(0xFF0DA64A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...replies.map(_reply),
              if (collapsible)
                _RepliesToggle(
                  label: 'Hide replies',
                  onTap: () => setState(() => _expanded = false),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _reply(Map<String, dynamic> reply) {
    final storedName = reply['authorName'];
    final author = storedName is String && storedName.trim().isNotEmpty
        ? storedName.trim()
        : 'Community member';
    final storedContent = reply['content'];
    final content = storedContent is String ? storedContent.trim() : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            author,
            style: GoogleFonts.lato(
              color: const Color(0xFF333333),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _timeAgo(reply['createdAt']),
            style: GoogleFonts.lato(
              color: const Color(0xFF8A8A8A),
              fontSize: 10,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              content,
              style: GoogleFonts.lato(
                color: const Color(0xFF444444),
                fontSize: 14,
                height: 1.42,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static DateTime _date(Map<String, dynamic> reply) {
    final value = reply['createdAt'];
    return value is Timestamp
        ? value.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _timeAgo(Object? value) {
    if (value is! Timestamp) return 'Just now';
    final difference = DateTime.now().difference(value.toDate());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hr ago';
    return '${difference.inDays}d ago';
  }
}

class _RepliesToggle extends StatelessWidget {
  const _RepliesToggle({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: GoogleFonts.lato(
            color: const Color(0xFF0DA64A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SwipeablePost extends StatefulWidget {
  const _SwipeablePost({
    required this.child,
    required this.onReport,
    required this.onReply,
    this.onDelete,
  });

  final Widget child;
  final VoidCallback onReport;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  @override
  State<_SwipeablePost> createState() => _SwipeablePostState();
}

class _SwipeablePostState extends State<_SwipeablePost> {
  double get _actionsWidth => widget.onDelete == null ? 120 : 180;
  double _offset = 0;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(-_actionsWidth, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final open =
        _offset.abs() > _actionsWidth / 3 ||
        details.primaryVelocity != null && details.primaryVelocity! < -250;
    setState(() => _offset = open ? -_actionsWidth : 0);
  }

  void _runAction(VoidCallback action) {
    setState(() => _offset = 0);
    action();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          IgnorePointer(
            ignoring: _offset == 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _offset == 0 ? 0 : 1,
              child: SizedBox(
                width: _actionsWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SwipeAction(
                      icon: Icons.reply_rounded,
                      label: 'Reply',
                      backgroundColor: const Color(0xFF12B76A),
                      foregroundColor: Colors.white,
                      onTap: () => _runAction(widget.onReply),
                    ),
                    _SwipeAction(
                      icon: Icons.error_outline_rounded,
                      label: 'Flag',
                      backgroundColor: const Color(0xFFA9A9A9),
                      foregroundColor: Colors.white,
                      onTap: () => _runAction(widget.onReport),
                    ),
                    if (widget.onDelete case final onDelete?)
                      _SwipeAction(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete',
                        backgroundColor: const Color(0xFFFF444B),
                        foregroundColor: Colors.white,
                        onTap: () => _runAction(onDelete),
                      ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_offset, 0, 0),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTap: _offset == 0 ? null : () => setState(() => _offset = 0),
              child: ColoredBox(
                color: Colors.white,
                child: SizedBox(width: double.infinity, child: widget.child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeAction extends StatelessWidget {
  const _SwipeAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 54,
          height: 58,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: foregroundColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.lato(
                  color: foregroundColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
