const APK_URL = 'https://github.com/zarsalene/Quran_AI_app/releases/latest/download/Rattil.apk';
const REPO_URL = 'https://github.com/zarsalene/Quran_AI_app';

const copy = {
  en: {
    skip:'Skip to content',languageLabel:'Choose language',navFeatures:'Features',navValues:'Our values',navDownload:'Download',getApp:'Get Rattil',eyebrow:'A little closer, every day',heroTitle:'Your journey with the Quran starts here.',heroBody:'Rattil is a free Android app to help you read the Quran, improve your recitation, and build a steady memorization habit. No ads. No account required.',downloadPrimary:'Download Rattil for Android',explore:'Explore the features',downloadMeta:'Android APK',free:'Free',trustLine:'Made with care. Your recitation stays on your device.',artCaption:'A quiet space for your Quran journey',read:'Read',listen:'Listen',memorize:'Memorize',artNoteTop:'Read at your own pace',artNoteBottom:'A practice that stays with you',scroll:'Discover Rattil',featuresEyebrow:'Everything in one place',featuresTitle:'Learn in a way that feels right.',featuresIntro:'Make space for a little Quran each day. Read, listen, practise, and return to what you have learned.',featureCards:[
      {icon:'book',title:'Read the Quran',body:'A complete 604-page Madani Mushaf, with page-by-page or verse-by-verse reading. Search, save bookmarks, adjust text size, and choose a light or dark theme.',detail:'Readings: Hafs · Warsh · Qalun · Shuʿba · al-Bazzi · Qunbul'},
      {icon:'audio',title:'Listen and follow along',body:'Listen to Al-Husary (Muʿallim) or Mishary Alafasy. Follow word highlighting, repeat verses, and adjust playback speed.',detail:'Al-Fatiha and Juz ʿAmma audio are included. Other Alafasy surahs can be downloaded for offline listening.'},
      {icon:'mic',title:'Practise with the voice teacher',body:'Recite into your device microphone and get word-level feedback from on-device speech recognition. Choose strict or gentle feedback.',detail:'Automatic feedback can make mistakes. It does not replace a qualified Quran teacher.'},
      {icon:'spark',title:'Memorize with Hifz',body:'Listen, read along, recite with text hidden, then test your recall. A spaced revision plan helps you revisit ayahs over time.',detail:'Your memorization progress is stored on your device.'},
      {icon:'progress',title:'See your progress',body:'Set a daily goal, keep a gentle streak, and see an overview of memorized ayahs and surahs.',detail:'Progress stays on your device. No account or sync is needed.'}
    ],teacherDisclaimer:'Recitation feedback is a learning aid and can be wrong. It is not a substitute for learning with a qualified Quran teacher.',valuesEyebrow:'Made with care and intention',valuesTitle:'Made for the love of the Quran.',valuesIntro:'A simple, non-commercial project to make Quran learning more accessible, wherever you are.',valuesQuote:'If Rattil benefits you, please remember everyone who contributed in your duʿa.',valueItems:['Free to use','No advertisements','No account required','No analytics or tracking in the app','Voice processing happens on your device','Read offline; some recitation audio is available offline'],downloadEyebrow:'Your next step',downloadTitle:'Start your journey today.',downloadBody:'Take the Quran with you. Read, listen, memorize, and practise at your own pace.',downloadFinal:'Download Rattil APK',tagFree:'Free',tagAndroid:'Android APK',tagNoAccount:'No account required',installTitle:'Install in a few steps',installSteps:['Download the APK file.','Open the downloaded file.','If Android asks, allow installs from this source.','Install Rattil, then open the app.'],securityNote:'Android may show a security warning when you install an APK outside Google Play. Only allow the install for this file if you chose to download it from Rattil’s official release.',footerTagline:'A free Quran learning project.',footerDownload:'Download the app',footerSource:'View source on GitHub',footerPrivacy:'Privacy policy'
  },
  fr: {
    skip:'Aller au contenu',languageLabel:'Choisir la langue',navFeatures:'Fonctionnalités',navValues:'Nos valeurs',navDownload:'Télécharger',getApp:'Découvrir Rattil',eyebrow:'Un peu plus près, chaque jour',heroTitle:'Votre chemin avec le Coran commence ici.',heroBody:'Rattil est une application Android gratuite pour vous aider à lire le Coran, améliorer votre récitation et créer une habitude régulière de mémorisation. Sans publicité ni compte.',downloadPrimary:'Télécharger Rattil pour Android',explore:'Découvrir les fonctionnalités',downloadMeta:'APK Android',free:'Gratuit',trustLine:'Conçu avec soin. Votre récitation reste sur votre appareil.',artCaption:'Un espace paisible pour votre cheminement',read:'Lire',listen:'Écouter',memorize:'Mémoriser',artNoteTop:'À votre propre rythme',artNoteBottom:'Une pratique qui vous accompagne',scroll:'Découvrir Rattil',featuresEyebrow:'Tout au même endroit',featuresTitle:'Apprenez à votre rythme.',featuresIntro:'Faites une place au Coran chaque jour. Lisez, écoutez, pratiquez et revenez sur vos acquis.',featureCards:[
      {icon:'book',title:'Lire le Coran',body:'Un Mushaf madani complet de 604 pages, à lire page par page ou verset par verset. Recherchez, ajoutez des signets, ajustez la taille du texte et choisissez le thème clair ou sombre.',detail:'Lectures : Hafs · Warsh · Qalun · Shuʿba · al-Bazzi · Qunbul'},
      {icon:'audio',title:'Écouter et suivre',body:'Écoutez Al-Husary (Muʿallim) ou Mishary Alafasy. Suivez la mise en évidence des mots, répétez les versets et réglez la vitesse.',detail:'Al-Fatiha et Juz ʿAmma sont inclus. Les autres sourates d’Alafasy se téléchargent pour une écoute hors ligne.'},
      {icon:'mic',title:'Pratiquer avec le professeur vocal',body:'Récitez avec le microphone de l’appareil et recevez un retour mot par mot grâce à la reconnaissance vocale locale. Choisissez un retour strict ou souple.',detail:'Le retour automatique peut se tromper. Il ne remplace pas un enseignant qualifié du Coran.'},
      {icon:'spark',title:'Mémoriser avec Hifz',body:'Écoutez, lisez en suivant, récitez avec le texte masqué, puis testez votre mémoire. Un programme de révision espacée vous aide à revoir les versets.',detail:'Votre progression de mémorisation reste sur votre appareil.'},
      {icon:'progress',title:'Suivre votre progression',body:'Fixez un objectif quotidien, entretenez une série sans pression et consultez les versets et sourates mémorisés.',detail:'Votre progression reste sur votre appareil. Aucun compte ni synchronisation ne sont nécessaires.'}
    ],teacherDisclaimer:'Le retour sur la récitation est une aide à l’apprentissage qui peut se tromper. Il ne remplace pas l’apprentissage auprès d’un enseignant qualifié du Coran.',valuesEyebrow:'Avec soin et intention',valuesTitle:'Fait par amour du Coran.',valuesIntro:'Un projet non commercial et simple pour rendre l’apprentissage du Coran plus accessible, où que vous soyez.',valuesQuote:'Si Rattil vous est utile, pensez à toutes les personnes qui y ont contribué dans vos duʿas.',valueItems:['Gratuit','Sans publicité','Sans compte','Sans analyse ni suivi dans l’application','Traitement vocal sur votre appareil','Lecture hors ligne ; certains audios sont disponibles hors ligne'],downloadEyebrow:'À vous de commencer',downloadTitle:'Commencez votre cheminement.',downloadBody:'Gardez le Coran avec vous. Lisez, écoutez, mémorisez et pratiquez à votre rythme.',downloadFinal:'Télécharger l’APK Rattil',tagFree:'Gratuit',tagAndroid:'APK Android',tagNoAccount:'Sans compte',installTitle:'Installation en quelques étapes',installSteps:['Téléchargez le fichier APK.','Ouvrez le fichier téléchargé.','Si Android le demande, autorisez les installations depuis cette source.','Installez Rattil, puis ouvrez l’application.'],securityNote:'Android peut afficher un avertissement de sécurité lors de l’installation d’un APK hors de Google Play. Autorisez uniquement ce fichier si vous l’avez téléchargé depuis la publication officielle de Rattil.',footerTagline:'Un projet gratuit pour apprendre le Coran.',footerDownload:'Télécharger l’application',footerSource:'Voir le code sur GitHub',footerPrivacy:'Confidentialité'
  },
  ar: {
    skip:'انتقل إلى المحتوى',languageLabel:'اختر اللغة',navFeatures:'المزايا',navValues:'قيمنا',navDownload:'التنزيل',getApp:'نزّل رتّل',eyebrow:'خطوة أقرب كل يوم',heroTitle:'رحلتك مع القرآن تبدأ من هنا.',heroBody:'رتّل تطبيق مجاني لنظام أندرويد يساعدك على قراءة القرآن وتحسين تلاوتك وبناء عادة ثابتة للحفظ. بلا إعلانات ولا حاجة إلى حساب.',downloadPrimary:'نزّل رتّل لأندرويد',explore:'اكتشف المزايا',downloadMeta:'تطبيق أندرويد APK',free:'مجاني',trustLine:'صُنع بعناية. تلاوتك تبقى على جهازك.',artCaption:'مساحة هادئة لرحلتك مع القرآن',read:'اقرأ',listen:'استمع',memorize:'احفظ',artNoteTop:'اقرأ على مهل',artNoteBottom:'عبادة ترافقك',scroll:'اكتشف رتّل',featuresEyebrow:'كل ما تحتاجه في مكان واحد',featuresTitle:'تعلّم بالطريقة التي تناسبك.',featuresIntro:'اجعل للقرآن وقتًا كل يوم. اقرأ واستمع وتدرّب وراجع ما تعلمته.',featureCards:[
      {icon:'book',title:'اقرأ القرآن',body:'مصحف مدني كامل من 604 صفحات، للقراءة صفحةً صفحة أو آيةً آية. ابحث وأضف علامات واضبط حجم النص واختر المظهر الفاتح أو الداكن.',detail:'الروايات: حفص · ورش · قالون · شعبة · البزي · قنبل'},
      {icon:'audio',title:'استمع وتابع',body:'استمع إلى الحصري (المعلّم) أو مشاري العفاسي. تابع تمييز الكلمات وكرّر الآيات واضبط سرعة التشغيل.',detail:'الفاتحة وجزء عمّ متاحان ضمن التطبيق. ويمكن تنزيل بقية سور العفاسي للاستماع دون إنترنت.'},
      {icon:'mic',title:'تدرّب مع المعلّم الصوتي',body:'اقرأ بصوتك عبر ميكروفون الجهاز واحصل على ملاحظات لكل كلمة باستخدام التعرّف الصوتي على الجهاز. اختر الملاحظات الصارمة أو اللطيفة.',detail:'قد يخطئ التقييم التلقائي، ولا يغني عن التعلّم على يد معلّم قرآن مؤهل.'},
      {icon:'spark',title:'احفظ مع برنامج الحفظ',body:'استمع، واقرأ مع التلاوة، ثم اقرأ من الذاكرة واختبر حفظك. تساعدك خطة مراجعة متباعدة على مراجعة الآيات.',detail:'يُحفظ تقدّمك في الحفظ على جهازك.'},
      {icon:'progress',title:'تابع تقدّمك',body:'حدّد هدفًا يوميًا، وحافظ على استمرارية لطيفة، واطّلع على الآيات والسور التي حفظتها.',detail:'يبقى تقدّمك على جهازك. لا تحتاج إلى حساب أو مزامنة.'}
    ],teacherDisclaimer:'ملاحظات التلاوة وسيلة للتعلّم وقد تخطئ. وهي لا تغني عن التعلّم على يد معلّم قرآن مؤهل.',valuesEyebrow:'عناية وإخلاص',valuesTitle:'صُنع حبًا بالقرآن.',valuesIntro:'مشروع بسيط غير تجاري لتيسير تعلّم القرآن أينما كنت.',valuesQuote:'إن انتفعت برتّل، فلا تنسَ كل من ساهم فيه من دعائك.',valueItems:['مجاني الاستخدام','بلا إعلانات','بلا حاجة إلى حساب','بلا تحليلات أو تتبّع داخل التطبيق','معالجة الصوت على جهازك','قراءة دون إنترنت؛ وبعض التلاوات متاحة دون اتصال'],downloadEyebrow:'خطوتك القادمة',downloadTitle:'ابدأ رحلتك اليوم.',downloadBody:'خذ القرآن معك. اقرأ واستمع واحفظ وتدرّب على مهل.',downloadFinal:'نزّل تطبيق رتّل APK',tagFree:'مجاني',tagAndroid:'تطبيق أندرويد APK',tagNoAccount:'لا يتطلب حسابًا',installTitle:'التثبيت في خطوات بسيطة',installSteps:['نزّل ملف APK.','افتح الملف الذي تم تنزيله.','إذا طلب أندرويد ذلك، اسمح بالتثبيت من هذا المصدر.','ثبّت رتّل ثم افتح التطبيق.'],securityNote:'قد يعرض أندرويد تحذيرًا أمنيًا عند تثبيت APK من خارج Google Play. اسمح بتثبيت هذا الملف فقط إذا نزّلته من إصدار رتّل الرسمي.',footerTagline:'مشروع مجاني لتعلّم القرآن.',footerDownload:'تنزيل التطبيق',footerSource:'المصدر على GitHub',footerPrivacy:'سياسة الخصوصية'
  }
};

const icons = {
  book:'<path d="M3.5 5.5c3.2-.9 6.1-.3 8.5 1.7v12c-2.4-2-5.3-2.6-8.5-1.7z"/><path d="M20.5 5.5c-3.2-.9-6.1-.3-8.5 1.7v12c2.4-2 5.3-2.6 8.5-1.7z"/>',
  audio:'<path d="M4 10v4h4l5 4V6l-5 4z"/><path d="M17 9a5 5 0 0 1 0 6m2.5-8.5a9 9 0 0 1 0 11"/>',
  mic:'<rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0M12 18v3m-4 0h8"/>',
  spark:'<path d="m12 3 1.5 5.5L19 10l-5.5 1.5L12 17l-1.5-5.5L5 10l5.5-1.5z"/><path d="m19 16 .8 2.2L22 19l-2.2.8L19 22l-.8-2.2L16 19l2.2-.8z"/>',
  progress:'<path d="M4 19V5m0 14h16"/><path d="m7 15 4-4 3 2 5-6"/><path d="M16 7h3v3"/>'
};

function chooseInitialLanguage() {
  const saved = localStorage.getItem('rattil-site-language');
  if (saved && copy[saved]) return saved;
  const languages = navigator.languages?.length ? navigator.languages : [navigator.language || 'en'];
  const match = languages.map(x => x.toLowerCase().split('-')[0]).find(x => copy[x]);
  return match || 'en';
}

function render(lang) {
  const t = copy[lang] || copy.en;
  document.documentElement.lang = lang;
  document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
  document.querySelector('#language').value = lang;
  document.title = ({en:'Rattil — Your journey with the Quran starts here',fr:'Rattil — Votre chemin avec le Coran commence ici',ar:'رتّل — رحلتك مع القرآن تبدأ من هنا'})[lang];
  document.querySelector('#language').setAttribute('aria-label', t.languageLabel);
  document.querySelectorAll('[data-i18n]').forEach(el => { el.textContent = t[el.dataset.i18n]; });
  document.querySelectorAll('[data-aria-i18n]').forEach(el => { el.setAttribute('aria-label', t[el.dataset.ariaI18n]); });
  document.querySelectorAll('[data-download]').forEach(el => { el.href = APK_URL; el.setAttribute('download','Rattil.apk'); });
  document.querySelector('.footer-links a:nth-child(2)').href = REPO_URL;
  document.querySelector('#feature-grid').innerHTML = t.featureCards.map((card, i) => `<article class="feature-card feature-card-${i+1}"><div class="feature-icon"><svg aria-hidden="true" viewBox="0 0 24 24">${icons[card.icon]}</svg></div><h3>${card.title}</h3><p>${card.body}</p><div class="feature-detail">${card.detail}</div></article>`).join('');
  document.querySelector('#values-list').innerHTML = t.valueItems.map(item => `<li><span aria-hidden="true">✓</span>${item}</li>`).join('');
  document.querySelector('#install-steps').innerHTML = t.installSteps.map(item => `<li>${item}</li>`).join('');
  document.querySelector('.desktop-nav').setAttribute('aria-label', ({en:'Primary navigation',fr:'Navigation principale',ar:'التنقل الرئيسي'})[lang]);
}

document.querySelector('#year').textContent = new Date().getFullYear();
const languageSelect = document.querySelector('#language');
languageSelect.addEventListener('change', () => {
  localStorage.setItem('rattil-site-language', languageSelect.value);
  render(languageSelect.value);
});
render(chooseInitialLanguage());
