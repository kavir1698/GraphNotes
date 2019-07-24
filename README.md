# GraphNotes

![](https://img.shields.io/badge/GraphNotes-v0.1.0-blue.svg)](https://github.com/kavir1698/GraphNotes) 

## What is it

Convert your research notes to a graph, so that finding a specific piece of information will be easier in the future.

Research requires remembering many facts and details with credible references. It is easy to forget a specific piece of information after a few days or months, or forget where you read it. Scientists usually mark PDF files or write down important details in text documents. These files can quickly pile up and make it tedious to find specific information.

A traditional method for gathering all the necessary information is using paper note cards. In a note card, we write specific information along with their references. We then organize the note cards and use them for writing papers or books. This method has a few drawbacks, namely, it will be difficult to keep all the cards organized as we add more of them, and it will become more difficult to find a specific card quickly. Therefore, people usually prepare and keep a separate set of note cards for each project. This is inefficient.

Introducing GraphNotes, I offer a solution to this problem. This is a software for organizing and easily retrieving scientific concepts. As you read textbooks or journal articles, you take notes of important definitions and sentences. GraphNotes converts your notes to a graph structure. Each node of such a graph has one concept. If two concepts have a relationship with each other, a link connect them in the graph. Each node (concept) and each link (relationship) can store multiple descriptions.

When you need to retrieve a specific information, all you need is to search for the concept you are looking for, and see all descriptions about it, and all of its relations with other concepts. The figure below shows a schematic view of how concepts and their relations are organized in GraphNotes. The figure shows descriptions for two concepts and a relation between them, in a graph with five nodes and five edges.

![solution](https://github.com/kavir1698/GraphNotes/blob/master/figures/graphnotesconcept.png)

## How to use it

* Write your notes in a text file. Any text format such as markdown would work.
* GraphNotes will read any line that starts with an asterisk "*".
  * Any word that is preceded with a hashtag "#" will be a node in the graph. E.g. #concept
    * If there are multiple works in a single concept, enclose them in "[]" and then precede it with a hashtag. E.g. #[multiple words]
  * To add citation to a description, put all the citations in a .bib file and cite the keys as follows: [@key1;@key2] 
That's all. You can then import your notes file using the `Add notes` button from the GUI.

Here is a complete example of a single note that will be converted into a graph:

```
* It has been long hypothesized that #scientists' choice of #[research problems] to work on are shaped by an ongoing tension between productive tradition and risky innovation [@Uzzi2018;@Bourdieu1975].
```

## Installation

To use pre-built binaries, copy the binary for your system from the `bin` folder and run it.

To compile it yourself, first install [nim](https://nim-lang.org/install.html) and then compile with `nim c GraphNotes.nim` in the `src` folder.