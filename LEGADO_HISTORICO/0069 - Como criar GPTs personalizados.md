# 0069 - Como criar GPTs personalizados

### USUÁRIO

resuma esse texto mantando os pontos principais e ensinamentos para me fornecer um resumo excelente:
In today's video I'll be showing you how to build your very own custom gpts because this new feature allows you to set up chat GPT in a way that is custom tailored to your very own needs and because this is no easy task I'll be providing you with a total of 10 gpts that you can copy paste straight from the free resource that I'm giving you into your very own account which will help you achieve exceptional results as

Soon as possible now before we dive right into the step by step I need to point out two things first of all as of right now this is only available to Enterprise and chat GPT plus users secondly and I feel like this is really important let's talk about what actually makes these special and why a lot of the internet kind of got it wrong let me elaborate so up until now everybody using cat GPT used the web interface right you could switch between 3.5 and

Four and then they added more and more including code interpreter custom instructions DOL plugins and more and now people have the perception with gpts coming out that everything changed gpts are this next level thing but what actually happened here is they just bundled everything into one package that is more user friendly because if you look at all the fields that I'll be showing you how to fill out in a second here you will realize that the first two

Are just packaging instructions are essentially custom instructions if you're following the channel I've been hammering the table about how important they are since months now Advanced prompt Engineers give all their context inside of their long prompt but for most people having instructions just like this setup for their very own use case was the best way to navigate chat GPT now they moved that in here and made it less confusing with just one field

Conversational starters are just prompts like we always had them and down here you have all the features that they've been rolling out over the last months okay maybe the knowledge Bas is slightly new here but you could do that with code interpreter but essentially what this does is it runs a prompt to condense your documents and then it searches over them so nothing really revolutionary here and capabilities heck you'll know that web browsing di code interpreter

Were all releases throughout the last month and here's the last one which gets people confused they think actions is this massive upgrades something that wasn't possible before well you know what these are these are just plugins if you have the technical ability to build API end points then you could have easily built a plugin before this matter of fact over a thousand of them popped up in the store and nobody was really using them so as you can see all of this

That we're about to cover isn't really new what is new is this GPT packaging and this userfriendly interface because now you set it up once and then it sits in your sidebar and then if I go to my copywriter here which you will receive with this video you can just pin it in the sidebar and it makes it really easy to navigate this because before gpts if I wanted to use all of these features if I wanted custom instructions code interpreter and plugins at the same time

Well some of those combos weren't even possible you couldn't have code interpreter and plugins on at the same time but the worst part was every time I wanted to switch custom instructions I had to go in I had to delete this delete this then go to a different file copy paste back into here and save and I had to do that every single time when I wanted to switch now you get to create these presets once and they sit in your sidebar and you can quickly access them

So this is the big thing that changed it's a user friendliness that makes this approachable to everybody that makes this stand out and just two sentences on the assistance API because because a lot of people ask about it that is essentially a programmatic version of using gpts main difference being that you pay for every single message but then you get the ability to embed it into other apps so if you build a no Cod chatbot you could use the assistant API

In there to interact with it but again in some of my tests when I uploaded a lot of files into that sending one message cost me around 8 cents whereas here it's included in your cat GPT Plus subscription okay so now let's get into building a highly specialized GPT so really the first step is heading over to chat. open.com the chat GPT website and now there's two ways to access the gpts one is up here under explore and the second one is when you click your name

Here under my gpts both those get you to this page where you can pick some of the presets down here so these are the ones that are created by open AI but the most interesting part here is right at the top create a GPT by clicking this button we will be able to enter the GPT Builder and now you really have two ways of approaching this okay one is by just talking to chat GPT and it will build the GPT for you but let me tell you that while this might be super user friendly

You just talk to it and it creates your GPT it's not extremely precise because the user friendliness has a price to it right and that's why in order to get way more control we'll be heading over to the configure tab over here which will present you with all these options now don't worry as mentioned I prepared 10 templates that you can copy paste straight into here that are set up to fit this entire template all you need to do is go to the first link in the

Description and sign up to my Weekly Newsletter it's completely free and it also allows me to send you updates once things change or we make it even better so this is the file that you will be getting and to anybody who has been around since a while you will be familiar with this but what we did now is we updated it with these gpts so if you just scroll down a little bit you'll have this section here with all the profiles and yes there's way more to

Explore in here but we'll just focus on these gpts because what I'm giving you is a full company worth of gpts you have 10 different assistants here that you can pick from as a starting template so for the sake of this video let's go with the product developer over here and the easiest way to do this is just to head on over to this gpts tab over here and now all you have to do is copy paste these various Fields into chat GPT so as we wanted the product developer I'll

Just copy the title and look even in my 4 14 in I can beautifully split screen this so into the name I'll put product developer and here I'll personalize it a little bit I'll say Igor's product developer for the description just hit this button that says copy to clipboard paste the description and for this main part where you give it the instructions how should it behave what are the goals of the GPT well here all I want you to do to get started is just hover over

These instructions and hit the copy to clipboard button again and paste them in here and look this is the point this is a super long and detailed description of what we want the GPT to do it specifies all the little details that you might not consider when just starting out we have things like the role the projects the challenges values and the background of the gpts and we've been developing these assistants since months just feel free to experiment with these but that's

Really it for the instructions next up we have a few options down here so let's talk about those so one of them is called conversation starters and what this really is it's prompt templates that are quickly accessible to the user of the GPT so here you should fill in some prompts that will be useful to the user of my product developer here and yes we prepared those to so you can just scroll a bit to the right here and you'll find match matching prompts so

For the product developer I have a list of 30 matching prompts here so now I can go through and pick the ones that I like as a conversation starter for my very own GPT so for example I'll take this one which is help in strategic planning again copy paste that then I'll take this one which creates Design Concepts and that should be good enough to start off now one side notice that as per usual with the prompts that we provide on this channel these do include

Variables so you can customize them to your own needs so if something is in square brackets feel free to change that to whatever suits your exact needs but I'll say this because there's so much information inside of the instructions already you can use these prompts with the brackets to it it will just assume the goals and the projects that are outlined in the instructions so if you'll love a Rec customizing something it's probably in here good so now we

Have two prompt templates leaving us with the last three options here and these are a little more advanced so let's briefly talk about them so here you can add additional knowledge and what this allows you to do is you can upload files and then Egor product developer will consider that file every time it seems relevant to what the user is asking for meaning if the user used the second prompt here can you create a sequence of innovative Design Concepts

And then as the knowledge you uploaded a specific design guideline like this Nike design guide that I got off the internet well if I decide to upload this it will consider that every time it's going to be designing something and the way to think about the knowledge that you want to add or some of the other capabilities or actions down here is really this if you just went out there and hired a brand new assistant what type of documents what type of knowledge would

Be helpful to him or her to complete the tasks that you want him or her to do well as they're assisting you with product development in this particular case design guidelines make sense but you might also want to consider uploading Excel sheet with all the products your company has with the prices and historic performance because the ne product developer will have the ability to consider that in its answers making them more valuable and the same

Thing goes for the capabilities and the actions down here so the capabilities are basically the different modalities of chat GPT that now they all merged into one so the first one is obviously about its ability to browse the internet the second one is the D free image generator and the third one is the code interpreter which that keep on most of the time because if you upload analytics this is really going to allow it to do more with that so with capabilities I

Would say when in doubt just leave all three of them on you can always change it later on and then last but certainly not least our actions and I would say these go beyond the scope of this tutorial because here you need a little bit of coding knowledge as you will be accessing external apis so a good way to think about this is that every single chat GPT plugin that you've seen so far is going to be accessible as an action here and then developers get to build

All types of tools that will integrate into here but as I said that's a little more advanced so all we'll do right now is have these detailed instructions and have all the capabilities oh and one more thing that we can do here is we also have an image so if you just open up this product developer like so then here we are let me just take a quick screenshot of her and I'll upload the photo giving it a bit more personality and that right there ladies and

Gentlemen is really it now we're ready to test it so if I full screen it you'll see that I get to test it in here we have the two prompt presets in here so let's just try the second one can you create a sequence of innovative Design Concepts for a product that encompasses functionality Aesthetics and user experience please provide bullet point summaries for each concept all right so in this case it really would benefit from us specifying the product so we'll

Do just that I'll go to the left here I'll change this product variable to chat GPT assistant Library okay so I'm pretty happy with the first version of Igor's product developer so I'll go to the top right I'll say save and here you get free choices okay so only me makes this private where nobody else has access to it and you'll just be using this for yourself only people with a link makes it semi-public where if people share your link around they'll

Get to access the GPT so be careful with that and then there's just plain public meaning it will be added to the store once that comes around I'll just make this one public say confirm and there you go now at the top right I have eegor product designer pinned so with these three dots I could hide it from the sidebar but why would I do that I'll just run the second prompt that we customized a little bit here and it's going to create a sequence of innovative

Designs now why would we go through all the steps of doing this right couldn't we just open up a new chat and run the prompt in there well certainly you could but look at what happens if you do that I'll just copy The Prompt new chat and I'll just run this in here and now we come back to what I said in the beginning because remember when I told you that chat GPT is just a general purpose tool and these gpts are assistants for specific purposes well

Look at this the general purpose tool gives us suggestions like AR assistants virtual librarian avatars and more but if we go into Igor's product designer as I mentioned the product developer has a whole set of values and preferences goals and approaches to working so because that is way more specific also our output is way more specific which is exactly what you want with these gpts right look at that modular interface design integrated workflow management

Modular interface design AI power design suggestions these are all things we could use as Innovative design concept when coming up with a new product as opposed to Classic cat GPT that just did its best at guessing but a lot of times that causes hallucinations and just plainly wrong guesses because it doesn't have the detailed information and another reason to use this is that you can always go back to this explore Tab and now I can edit my product developer

And make it better over time I can add more documents make the instructions even more specific to me and not to mention all the other features and advanced functionality down here and then you can just keep using the presets to create various gpts that fit your various roles so me as a YouTuber I'll have multiple gpts because I have to wear many hats in my work but maybe all you need is one or two that have the exact right data so again you can get

This template that also comes as a PDF as the first link in the description below on a quick side note it also comes with something I call the prompt Factory which is a prompt generator for the specific GPT so you just go to prompt Factory here and if I just copy this super long prompt from the product developer I can just open up a new chat paste this hit enter and it's going to generate 30 brand new prompts depending on the profiles so if you customize the

Profile over time it will also generate custom prompts yep there it goes so go get your 10 GPT assistants and start using them in your everyday work link is below as per usual and then for anybody who's ready to go a step further than this we're building out the ultimate version which is a massive library of 1,000 gpts right now we're at almost 700 but we're expanding this based on community feedback and what you get is more of what you just saw a web

Interface to easily access these and the course that goes into detail of how to get the maximum out of this product because there's really a lot here and especially the customization can be super valuable and that's exactly what we talk about in the videos here so now that we looked at how to build some of these it's time to explore what other people have been up to and what they built with this brand new feature and that's why I went ahead and picked out

Some of the most interesting gbds on the internet that were built within the first week and created this video that includes links to try them all I'll see you there

Please write in Portuguese language.

---

### ASSISTENTE

O vídeo aborda como criar GPTs personalizados, uma nova funcionalidade disponível apenas para usuários do Chat GPT Plus e Enterprise. O apresentador oferece 10 modelos pré-fabricados que podem ser copiados e colados diretamente na conta do usuário para resultados excepcionais. Ele enfatiza a importância das instruções personalizadas e dos iniciadores de conversa, mostrando como configurar esses elementos para criar assistentes virtuais específicos para diferentes necessidades.

O vídeo também esclarece um equívoco comum: muitos acreditam que os GPTs são uma inovação radical, mas, na realidade, eles são uma união de recursos já existentes em um pacote mais amigável ao usuário. Isso inclui instruções personalizadas, iniciadores de conversa, capacidades de navegação na web, interpretação de código e plug-ins. O apresentador demonstra como configurar um GPT, enfatizando a facilidade de uso e a personalização.

Ele também menciona a API de assistência, uma versão programática do Chat GPT que permite a incorporação em outros aplicativos. O vídeo finaliza com um convite para acessar uma biblioteca de GPTs e um curso que ensina a maximizar o uso desses recursos. O foco é na customização, mostrando como isso pode ser valioso para os usuários.

---

### USUÁRIO

como ele mostra criar e costumizar os gpts?

Please write in Portuguese language.

---

### ASSISTENTE

No vídeo, o processo de criar e customizar GPTs personalizados é explicado detalhadamente, seguindo estes passos:

1. **Acesso à Funcionalidade GPTs**: Primeiro, é necessário acessar a seção de GPTs personalizados no site do Chat GPT. Isso pode ser feito através da seção "Explore" ou clicando no nome do usuário e selecionando "My GPTs".

2. **Criar um Novo GPT**: Clicando em "Create a GPT", o usuário entra no GPT Builder, onde pode começar a personalização. Há duas opções: conversar com o Chat GPT para que ele construa o assistente ou usar a aba "Configure" para maior controle e precisão.

3. **Instruções Personalizadas**: O apresentador destaca a importância das instruções personalizadas, que definem como o GPT deve se comportar e quais são seus objetivos. Essas instruções são detalhadas e abrangem aspectos como o papel do GPT, desafios, valores e contexto.

4. **Iniciadores de Conversa**: São os modelos de prompt que podem ser rapidamente acessados pelo usuário do GPT. O vídeo sugere preencher essa seção com prompts úteis para o assistente específico que está sendo criado.

5. **Upload de Conhecimento Adicional**: O usuário pode adicionar documentos relevantes, como guias de design ou planilhas, que o GPT considerará em suas respostas, tornando-as mais precisas e valiosas.

6. **Capacidades e Ações**: Essas seções permitem adicionar funcionalidades como navegação na web, geração de imagens e interpretação de código. A seção de ações é mais avançada, permitindo a integração com APIs externas.

7. **Teste e Ajustes**: Após configurar o GPT, o usuário pode testá-lo e fazer ajustes conforme necessário, refinando as instruções e adicionando mais documentos ou capacidades.

8. **Publicação**: Por fim, o GPT personalizado pode ser salvo e definido como privado, semi-público ou público, dependendo da preferência do usuário.

O vídeo enfatiza que, embora os GPTs pareçam ser uma nova inovação, eles são na verdade uma combinação de recursos já existentes, agora apresentados de forma mais amigável e fácil de usar.

---

### USUÁRIO

faça o mesmo com esse texto;

Please write in Portuguese language.

---

### USUÁRIO

faça o mesmo com esse texto;
In today's video I'll be showing you how to build your very own custom gpts because this new feature allows you to set up chat GPT in a way that is custom tailored to your very own needs and because this is no easy task I'll be providing you with a total of 10 gpts that you can copy paste straight from the free resource that I'm giving you into your very own account which will help you achieve exceptional results as

Soon as possible now before we dive right into the step by step I need to point out two things first of all as of right now this is only available to Enterprise and chat GPT plus users secondly and I feel like this is really important let's talk about what actually makes these special and why a lot of the internet kind of got it wrong let me elaborate so up until now everybody using cat GPT used the web interface right you could switch between 3.5 and

Four and then they added more and more including code interpreter custom instructions DOL plugins and more and now people have the perception with gpts coming out that everything changed gpts are this next level thing but what actually happened here is they just bundled everything into one package that is more user friendly because if you look at all the fields that I'll be showing you how to fill out in a second here you will realize that the first two

Are just packaging instructions are essentially custom instructions if you're following the channel I've been hammering the table about how important they are since months now Advanced prompt Engineers give all their context inside of their long prompt but for most people having instructions just like this setup for their very own use case was the best way to navigate chat GPT now they moved that in here and made it less confusing with just one field

Conversational starters are just prompts like we always had them and down here you have all the features that they've been rolling out over the last months okay maybe the knowledge Bas is slightly new here but you could do that with code interpreter but essentially what this does is it runs a prompt to condense your documents and then it searches over them so nothing really revolutionary here and capabilities heck you'll know that web browsing di code interpreter

Were all releases throughout the last month and here's the last one which gets people confused they think actions is this massive upgrades something that wasn't possible before well you know what these are these are just plugins if you have the technical ability to build API end points then you could have easily built a plugin before this matter of fact over a thousand of them popped up in the store and nobody was really using them so as you can see all of this

That we're about to cover isn't really new what is new is this GPT packaging and this userfriendly interface because now you set it up once and then it sits in your sidebar and then if I go to my copywriter here which you will receive with this video you can just pin it in the sidebar and it makes it really easy to navigate this because before gpts if I wanted to use all of these features if I wanted custom instructions code interpreter and plugins at the same time

Well some of those combos weren't even possible you couldn't have code interpreter and plugins on at the same time but the worst part was every time I wanted to switch custom instructions I had to go in I had to delete this delete this then go to a different file copy paste back into here and save and I had to do that every single time when I wanted to switch now you get to create these presets once and they sit in your sidebar and you can quickly access them

So this is the big thing that changed it's a user friendliness that makes this approachable to everybody that makes this stand out and just two sentences on the assistance API because because a lot of people ask about it that is essentially a programmatic version of using gpts main difference being that you pay for every single message but then you get the ability to embed it into other apps so if you build a no Cod chatbot you could use the assistant API

In there to interact with it but again in some of my tests when I uploaded a lot of files into that sending one message cost me around 8 cents whereas here it's included in your cat GPT Plus subscription okay so now let's get into building a highly specialized GPT so really the first step is heading over to chat. open.com the chat GPT website and now there's two ways to access the gpts one is up here under explore and the second one is when you click your name

Here under my gpts both those get you to this page where you can pick some of the presets down here so these are the ones that are created by open AI but the most interesting part here is right at the top create a GPT by clicking this button we will be able to enter the GPT Builder and now you really have two ways of approaching this okay one is by just talking to chat GPT and it will build the GPT for you but let me tell you that while this might be super user friendly

You just talk to it and it creates your GPT it's not extremely precise because the user friendliness has a price to it right and that's why in order to get way more control we'll be heading over to the configure tab over here which will present you with all these options now don't worry as mentioned I prepared 10 templates that you can copy paste straight into here that are set up to fit this entire template all you need to do is go to the first link in the

Description and sign up to my Weekly Newsletter it's completely free and it also allows me to send you updates once things change or we make it even better so this is the file that you will be getting and to anybody who has been around since a while you will be familiar with this but what we did now is we updated it with these gpts so if you just scroll down a little bit you'll have this section here with all the profiles and yes there's way more to

Explore in here but we'll just focus on these gpts because what I'm giving you is a full company worth of gpts you have 10 different assistants here that you can pick from as a starting template so for the sake of this video let's go with the product developer over here and the easiest way to do this is just to head on over to this gpts tab over here and now all you have to do is copy paste these various Fields into chat GPT so as we wanted the product developer I'll

Just copy the title and look even in my 4 14 in I can beautifully split screen this so into the name I'll put product developer and here I'll personalize it a little bit I'll say Igor's product developer for the description just hit this button that says copy to clipboard paste the description and for this main part where you give it the instructions how should it behave what are the goals of the GPT well here all I want you to do to get started is just hover over

These instructions and hit the copy to clipboard button again and paste them in here and look this is the point this is a super long and detailed description of what we want the GPT to do it specifies all the little details that you might not consider when just starting out we have things like the role the projects the challenges values and the background of the gpts and we've been developing these assistants since months just feel free to experiment with these but that's

Really it for the instructions next up we have a few options down here so let's talk about those so one of them is called conversation starters and what this really is it's prompt templates that are quickly accessible to the user of the GPT so here you should fill in some prompts that will be useful to the user of my product developer here and yes we prepared those to so you can just scroll a bit to the right here and you'll find match matching prompts so

For the product developer I have a list of 30 matching prompts here so now I can go through and pick the ones that I like as a conversation starter for my very own GPT so for example I'll take this one which is help in strategic planning again copy paste that then I'll take this one which creates Design Concepts and that should be good enough to start off now one side notice that as per usual with the prompts that we provide on this channel these do include

Variables so you can customize them to your own needs so if something is in square brackets feel free to change that to whatever suits your exact needs but I'll say this because there's so much information inside of the instructions already you can use these prompts with the brackets to it it will just assume the goals and the projects that are outlined in the instructions so if you'll love a Rec customizing something it's probably in here good so now we

Have two prompt templates leaving us with the last three options here and these are a little more advanced so let's briefly talk about them so here you can add additional knowledge and what this allows you to do is you can upload files and then Egor product developer will consider that file every time it seems relevant to what the user is asking for meaning if the user used the second prompt here can you create a sequence of innovative Design Concepts

And then as the knowledge you uploaded a specific design guideline like this Nike design guide that I got off the internet well if I decide to upload this it will consider that every time it's going to be designing something and the way to think about the knowledge that you want to add or some of the other capabilities or actions down here is really this if you just went out there and hired a brand new assistant what type of documents what type of knowledge would

Be helpful to him or her to complete the tasks that you want him or her to do well as they're assisting you with product development in this particular case design guidelines make sense but you might also want to consider uploading Excel sheet with all the products your company has with the prices and historic performance because the ne product developer will have the ability to consider that in its answers making them more valuable and the same

Thing goes for the capabilities and the actions down here so the capabilities are basically the different modalities of chat GPT that now they all merged into one so the first one is obviously about its ability to browse the internet the second one is the D free image generator and the third one is the code interpreter which that keep on most of the time because if you upload analytics this is really going to allow it to do more with that so with capabilities I

Would say when in doubt just leave all three of them on you can always change it later on and then last but certainly not least our actions and I would say these go beyond the scope of this tutorial because here you need a little bit of coding knowledge as you will be accessing external apis so a good way to think about this is that every single chat GPT plugin that you've seen so far is going to be accessible as an action here and then developers get to build

All types of tools that will integrate into here but as I said that's a little more advanced so all we'll do right now is have these detailed instructions and have all the capabilities oh and one more thing that we can do here is we also have an image so if you just open up this product developer like so then here we are let me just take a quick screenshot of her and I'll upload the photo giving it a bit more personality and that right there ladies and

Gentlemen is really it now we're ready to test it so if I full screen it you'll see that I get to test it in here we have the two prompt presets in here so let's just try the second one can you create a sequence of innovative Design Concepts for a product that encompasses functionality Aesthetics and user experience please provide bullet point summaries for each concept all right so in this case it really would benefit from us specifying the product so we'll

Do just that I'll go to the left here I'll change this product variable to chat GPT assistant Library okay so I'm pretty happy with the first version of Igor's product developer so I'll go to the top right I'll say save and here you get free choices okay so only me makes this private where nobody else has access to it and you'll just be using this for yourself only people with a link makes it semi-public where if people share your link around they'll

Get to access the GPT so be careful with that and then there's just plain public meaning it will be added to the store once that comes around I'll just make this one public say confirm and there you go now at the top right I have eegor product designer pinned so with these three dots I could hide it from the sidebar but why would I do that I'll just run the second prompt that we customized a little bit here and it's going to create a sequence of innovative

Designs now why would we go through all the steps of doing this right couldn't we just open up a new chat and run the prompt in there well certainly you could but look at what happens if you do that I'll just copy The Prompt new chat and I'll just run this in here and now we come back to what I said in the beginning because remember when I told you that chat GPT is just a general purpose tool and these gpts are assistants for specific purposes well

Look at this the general purpose tool gives us suggestions like AR assistants virtual librarian avatars and more but if we go into Igor's product designer as I mentioned the product developer has a whole set of values and preferences goals and approaches to working so because that is way more specific also our output is way more specific which is exactly what you want with these gpts right look at that modular interface design integrated workflow management

Modular interface design AI power design suggestions these are all things we could use as Innovative design concept when coming up with a new product as opposed to Classic cat GPT that just did its best at guessing but a lot of times that causes hallucinations and just plainly wrong guesses because it doesn't have the detailed information and another reason to use this is that you can always go back to this explore Tab and now I can edit my product developer

And make it better over time I can add more documents make the instructions even more specific to me and not to mention all the other features and advanced functionality down here and then you can just keep using the presets to create various gpts that fit your various roles so me as a YouTuber I'll have multiple gpts because I have to wear many hats in my work but maybe all you need is one or two that have the exact right data so again you can get

This template that also comes as a PDF as the first link in the description below on a quick side note it also comes with something I call the prompt Factory which is a prompt generator for the specific GPT so you just go to prompt Factory here and if I just copy this super long prompt from the product developer I can just open up a new chat paste this hit enter and it's going to generate 30 brand new prompts depending on the profiles so if you customize the

Profile over time it will also generate custom prompts yep there it goes so go get your 10 GPT assistants and start using them in your everyday work link is below as per usual and then for anybody who's ready to go a step further than this we're building out the ultimate version which is a massive library of 1,000 gpts right now we're at almost 700 but we're expanding this based on community feedback and what you get is more of what you just saw a web

Interface to easily access these and the course that goes into detail of how to get the maximum out of this product because there's really a lot here and especially the customization can be super valuable and that's exactly what we talk about in the videos here so now that we looked at how to build some of these it's time to explore what other people have been up to and what they built with this brand new feature and that's why I went ahead and picked out

Some of the most interesting gbds on the internet that were built within the first week and created this video that includes links to try them all I'll see you there


Please write in Portuguese language.

---

### ASSISTENTE

Certamente

---

### ASSISTENTE

O vídeo aborda a criação de GPTs personalizados, destacando que a funcionalidade está disponível apenas para usuários do Enterprise e Chat GPT Plus. O apresentador fornecerá 10 GPTs pré-configurados que podem ser copiados e colados diretamente em uma conta, prometendo resultados excepcionais.

Ele explica que, embora muitos acreditem que os GPTs sejam uma inovação radical, eles são na verdade a junção de recursos já existentes em um pacote mais amigável ao usuário. Isso inclui interpretação de código, instruções personalizadas e plug-ins. O apresentador demonstra como configurar um GPT, enfatizando a facilidade de uso e a personalização.

São destacadas as etapas para a criação de um GPT:
1. Acessar a seção de GPTs personalizados no site do Chat GPT.
2. Criar um novo GPT usando a aba "Configure" para mais controle.
3. Incluir instruções detalhadas, definindo o comportamento e objetivos do GPT.
4. Adicionar iniciadores de conversa, que são modelos de prompts rápidos para o usuário.
5. Inserir conhecimento adicional, como upload de arquivos relevantes, para respostas mais precisas.
6. Configurar capacidades, como navegação na web e interpretação de código.

O apresentador também menciona a API de assistência, uma versão programática do uso de GPTs. No final, ele fala sobre a disponibilidade de um modelo que inclui uma biblioteca de 1.000 GPTs e um curso para maximizar o uso desses recursos, focando na customização. O vídeo conclui incentivando os espectadores a explorar GPTs criados por outras pessoas e a usar os recursos fornecidos para melhorar seu trabalho diário.

---

