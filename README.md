# PersonSearchUsingSQLVectorDatatype
Not every POC is a successful POC—and that’s perfectly okay! 😊



Recently, I worked on a proof of concept to explore if the new vector data type could be used to enhance fuzzy search. My initial hypothesis was that leveraging vector similarity could make fuzzy searches more efficient. However, the journey led to a surprising realization: semantic search and fuzzy search are fundamentally different, and trying to achieve both with the same solution isn’t practical. In hindsight, it seems so obvious! 🙃



To break it down:



Semantic search is all about understanding meaning and context. It involves comparing high-dimensional embeddings (like vector representations of words or phrases) to find semantically similar items. For example, a search for "car" might also surface results for "automobile" or "vehicle."



Fuzzy search, on the other hand, is designed to handle typos, misspellings, or close matches by looking for small textual differences. Think of searching for "Jonh" and finding results for "John."



These two use cases serve very different needs, and while vector data types are powerful for semantic similarity, they are not well-suited for handling character-level edits or textual proximity.



The original intent of this repo was to demonstrate vector data type usage for fuzzy search. Instead, it turned into an example of how not to approach the problem. 😄
