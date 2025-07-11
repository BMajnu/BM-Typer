import 'package:bm_typer/core/models/lesson_model.dart';

/// Collection of English paragraph typing exercises
final List<Lesson> englishLessons = [
  // Famous Quotes Lesson
  Lesson(
    title: "Famous Quotes",
    description:
        "Practice typing with inspirational and thought-provoking quotes from famous individuals.",
    category: "English",
    difficultyLevel: 2,
    language: "en",
    exercises: [
      Exercise(
        text:
            "The greatest glory in living lies not in never falling, but in rising every time we fall. - Nelson Mandela",
        type: ExerciseType.quote,
        difficultyLevel: 2,
        source: "Nelson Mandela",
      ),
      Exercise(
        text:
            "The way to get started is to quit talking and begin doing. - Walt Disney",
        type: ExerciseType.quote,
        difficultyLevel: 1,
        source: "Walt Disney",
      ),
      Exercise(
        text:
            "Your time is limited, so don't waste it living someone else's life. Don't be trapped by dogma – which is living with the results of other people's thinking. - Steve Jobs",
        type: ExerciseType.quote,
        difficultyLevel: 3,
        source: "Steve Jobs",
      ),
      Exercise(
        text:
            "If life were predictable it would cease to be life, and be without flavor. - Eleanor Roosevelt",
        type: ExerciseType.quote,
        difficultyLevel: 2,
        source: "Eleanor Roosevelt",
      ),
      Exercise(
        text:
            "If you look at what you have in life, you'll always have more. If you look at what you don't have in life, you'll never have enough. - Oprah Winfrey",
        type: ExerciseType.quote,
        difficultyLevel: 2,
        source: "Oprah Winfrey",
      ),
    ],
  ),

  // Literature Excerpts
  Lesson(
    title: "Literary Classics",
    description: "Practice typing with excerpts from famous literary works.",
    category: "English",
    difficultyLevel: 3,
    language: "en",
    exercises: [
      Exercise(
        text:
            "It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair.",
        type: ExerciseType.paragraph,
        difficultyLevel: 3,
        source: "A Tale of Two Cities by Charles Dickens",
      ),
      Exercise(
        text:
            "All happy families are alike; each unhappy family is unhappy in its own way.",
        type: ExerciseType.quote,
        difficultyLevel: 2,
        source: "Anna Karenina by Leo Tolstoy",
      ),
      Exercise(
        text:
            "In my younger and more vulnerable years my father gave me some advice that I've been turning over in my mind ever since. 'Whenever you feel like criticizing anyone,' he told me, 'just remember that all the people in this world haven't had the advantages that you've had.'",
        type: ExerciseType.paragraph,
        difficultyLevel: 3,
        source: "The Great Gatsby by F. Scott Fitzgerald",
      ),
      Exercise(
        text:
            "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
        type: ExerciseType.quote,
        difficultyLevel: 3,
        source: "Pride and Prejudice by Jane Austen",
      ),
    ],
  ),

  // Business Writing
  Lesson(
    title: "Business Communication",
    description: "Practice typing common business phrases and emails.",
    category: "English",
    difficultyLevel: 2,
    language: "en",
    exercises: [
      Exercise(
        text:
            "Dear Team,\n\nI hope this email finds you well. I wanted to follow up on our discussion from yesterday's meeting regarding the quarterly sales targets. As mentioned, we need to increase our outreach efforts to meet our goals by the end of this quarter.\n\nPlease review the attached document and provide your feedback by Friday.\n\nBest regards,\nProject Manager",
        type: ExerciseType.business,
        difficultyLevel: 3,
      ),
      Exercise(
        text:
            "Thank you for your prompt response. I appreciate your attention to this matter and look forward to our continued collaboration on this project.",
        type: ExerciseType.business,
        difficultyLevel: 2,
      ),
      Exercise(
        text:
            "I am writing to confirm our meeting scheduled for Thursday, June 15th at 2:00 PM in Conference Room B. Please let me know if this time still works for you.",
        type: ExerciseType.business,
        difficultyLevel: 2,
      ),
      Exercise(
        text:
            "We are pleased to inform you that your application has been successful. We would like to invite you for an interview at our office next week to discuss the position in more detail.",
        type: ExerciseType.business,
        difficultyLevel: 2,
      ),
    ],
  ),

  // Advanced Paragraphs
  Lesson(
    title: "Advanced Paragraphs",
    description: "Challenge yourself with longer, more complex paragraphs.",
    category: "English",
    difficultyLevel: 4,
    language: "en",
    exercises: [
      Exercise(
        text:
            "The technological innovation of the past few decades has been remarkable. From the advent of personal computers to smartphones and artificial intelligence, we have witnessed unprecedented change in how we live, work, and communicate. These advancements have created new industries, transformed existing ones, and fundamentally altered social interactions across the globe. As we continue to develop new technologies at an exponential rate, it becomes increasingly important to consider the ethical implications and ensure that progress benefits humanity as a whole.",
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text:
            "Climate change represents one of the most significant challenges facing our planet today. Rising global temperatures have led to melting ice caps, extreme weather events, and disruptions to ecosystems worldwide. Addressing this crisis requires coordinated international effort, substantial policy changes, and individual commitment to sustainable practices. While the scale of the problem can seem overwhelming, each action taken to reduce carbon emissions contributes to the collective solution needed to preserve our environment for future generations.",
        type: ExerciseType.paragraph,
        difficultyLevel: 4,
      ),
      Exercise(
        text:
            "The human brain is perhaps the most complex structure known to science. With approximately 86 billion neurons forming trillions of connections, it orchestrates everything from basic bodily functions to abstract thought and creativity. Neuroscientists continue to unravel its mysteries, discovering new insights about memory formation, decision-making processes, and the neurological basis of consciousness. Despite remarkable progress in brain research, we have only begun to understand the intricate mechanisms that make us who we are.",
        type: ExerciseType.paragraph,
        difficultyLevel: 5,
      ),
    ],
  ),

  // Specialized Drills
  Lesson(
    title: "English Typing Drills",
    description:
        "Focused exercises to improve specific typing challenges in English.",
    category: "English",
    difficultyLevel: 2,
    language: "en",
    exercises: [
      Exercise(
        text:
            "The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump!",
        type: ExerciseType.drill,
        difficultyLevel: 2,
        source: "Pangrams",
      ),
      Exercise(
        text:
            "Unique New York, unique New York, unique New York. Red leather, yellow leather, red leather, yellow leather.",
        type: ExerciseType.drill,
        difficultyLevel: 3,
        source: "Tongue Twisters",
      ),
      Exercise(
        text:
            "efficiency effectiveness excellent exceptional extraordinary experience expertise exemplary extensive external",
        type: ExerciseType.drill,
        difficultyLevel: 3,
        source: "E-words",
      ),
      Exercise(
        text:
            "their there they're your you're its it's whose who's affect effect accept except",
        type: ExerciseType.drill,
        difficultyLevel: 2,
        source: "Commonly Confused Words",
      ),
      Exercise(
        text: "12345 67890 !@#\$% ^&*() -=_+ []{}| ;': ,./",
        type: ExerciseType.drill,
        difficultyLevel: 3,
        source: "Numbers and Symbols",
      ),
    ],
  ),
];

class EnglishParagraphData {
  // Easy paragraphs (shorter sentences, common words)
  static const List<String> easyParagraphs = [
    "The quick brown fox jumps over the lazy dog. This simple sentence contains every letter of the English alphabet. It is often used to test typewriters and computer keyboards. The sentence is a pangram, which means it uses every letter of the alphabet.",
    "I enjoy reading books in my free time. Books can take us to new worlds and teach us new things. Some people like fiction while others prefer non-fiction. Libraries are great places to find books on any subject you can imagine.",
    "Cooking is a useful skill that everyone should learn. Simple meals can be both healthy and delicious. Fresh ingredients often make the best dishes. Remember to wash your hands before preparing food. Many recipes can be found online for free.",
    "Exercise is important for maintaining good health. Walking is an easy way to stay active every day. Swimming is another great form of exercise that works many muscles. Even just stretching for a few minutes can help you feel better.",
    "The sun rises in the east and sets in the west. During the day, the sky is usually blue. At night, we can sometimes see the moon and stars. Clouds can block our view of the sky. Weather patterns change with the seasons.",
  ];

  // Medium paragraphs (moderate length, some complex words)
  static const List<String> mediumParagraphs = [
    "Technology continues to evolve at a remarkable pace, transforming how we communicate, work, and live our daily lives. Smartphones have become essential tools, connecting us to vast networks of information and people around the globe. As artificial intelligence advances, we must consider both its benefits and potential challenges to society.",
    "The human brain is perhaps the most complex structure in the known universe. Containing approximately 86 billion neurons, it processes information, stores memories, and controls our bodies with remarkable efficiency. Scientists continue to discover new aspects of brain function, though many mysteries remain unsolved despite decades of intensive research.",
    "Climate change represents one of the most significant challenges facing humanity in the 21st century. Rising global temperatures have been linked to increased frequency of extreme weather events, rising sea levels, and disruptions to ecosystems worldwide. International cooperation will be essential to developing effective strategies for mitigation and adaptation.",
    "Democracy depends on an informed citizenry and transparent institutions to function properly. Voting rights, freedom of speech, and independent media serve as crucial pillars supporting democratic governance. When these foundations are weakened, societies may experience polarization, decreased civic engagement, and erosion of public trust in government.",
    "The global economy has become increasingly interconnected through trade, investment, and digital networks. While globalization has created new opportunities for growth and development, it has also highlighted disparities between and within nations. Finding balance between economic integration and addressing inequality remains a complex policy challenge.",
  ];

  // Hard paragraphs (longer sentences, technical/specialized vocabulary)
  static const List<String> hardParagraphs = [
    "Quantum computing represents a paradigm shift in computational capabilities, leveraging the principles of quantum mechanics such as superposition and entanglement to process information in fundamentally different ways than classical computers. While traditional bits exist in binary states of either 0 or 1, quantum bits (qubits) can exist in multiple states simultaneously, potentially enabling exponential increases in processing power for specific applications such as cryptography, material science, and complex system modeling.",
    "The anthropogenic impact on Earth's biosphere has accelerated to such a degree that many scientists now recognize the dawn of a new geological epoch: the Anthropocene. Characterized by widespread environmental modifications including atmospheric composition alterations, biodiversity reduction through habitat destruction and species extinction, and geomorphological changes through urbanization and resource extraction, this proposed epoch represents the first time a single species has become the dominant force shaping planetary systems and biogeochemical cycles.",
    "Neuroplasticity, the brain's remarkable ability to reorganize itself by forming new neural connections throughout life, challenges earlier beliefs that the brain structure was relatively immutable after critical developmental periods in childhood. Contemporary neuroscience research demonstrates that various experiences, including learning new skills, environmental changes, and recovering from injuries, can trigger synaptic pruning and dendritic growth, effectively rewiring neural pathways and potentially compensating for damaged regions through cortical remapping processes.",
    "The implementation of sophisticated machine learning algorithms in healthcare settings presents both unprecedented opportunities and significant ethical considerations. While artificial intelligence systems demonstrate increasing accuracy in diagnostic imaging interpretation, treatment protocol optimization, and predictive analytics for patient outcomes, questions regarding data privacy, algorithmic transparency, potential biases in training datasets, and the appropriate balance between automated systems and human clinical judgment remain incompletely resolved in contemporary medical practice and health policy frameworks.",
    "Contemporary linguistic theory has evolved substantially from the structural and transformational approaches that dominated the field through much of the twentieth century, incorporating insights from cognitive science, evolutionary biology, and computational modeling to develop more comprehensive frameworks for understanding language acquisition, processing, and change. Embodied cognition perspectives suggest that linguistic structures emerge from and remain grounded in sensorimotor experience, while construction grammar approaches emphasize the inseparability of syntactic patterns and semantic content, challenging traditional distinctions between lexicon and grammar in favor of viewing language as a complex network of form-meaning pairings at varying levels of abstraction and specificity.",
  ];
}
