Blueprint Mover

This work is based on the mod conman by justarndomgeek. It also contains a lot of conman code, that has no use for this mod.

It also contains inactive code, which is intended to be used in a large project of mine. Maybe someday, I will release it.

Operation:

See conman for basic explanation, of what cc1 and cc2 are. The comands work as follows:

cc1: I=1 (I for index): reindex blueprint book(s). Reindexes all blueprint books in the input of the machine. This means it adds the book page to the start of the name. Changes empty blueprints to contain one concrete tile. This makes it possible to export your book to the library and reimport it without deleting empty blueprints and duplicates. For use with conman or recursive blueprints, this can be useful. Has the highest priority.

In all other cases, it copies a blueprint or book as defined by cc1 to the position defined by cc2, with regard for some other signals.

The Mover entity can contain any blueprint or book both in its in- and output inventory.

Finding a blueprint or book in an inventory works like this:

If there is a signal for any kind of blueprint book, it will take the first such signal (just dont send different book signals to it at the same time). If the signal is -1, it refers to the entire book. If it is positive, the signal value is taken as a page number. If there is no blueprint book, it will look for a blueprint signal.

It will always keep the order within a book. Example: If cc1 gets the signal book=5 and cc2 gets the signal book=10, it will overwrite blueprint number 10 in the blueprint book with a copy of blueprint number 5. If there are less then 10 pages in the book, it adds pages to the end of the book, until there are 10. 

O=1(O for output): If you set the signal O to one (or any non-zero number), it will find the position you want to move something to in the output inventory.

R=1, Position data as X,Y(R for remote): It will search for the specified input blueprint not in this machine, but in the mover at position x,y. Example: cc2: book=-1, cc1: book=-1, R=1, X,Y: Copies the book in the mover at postion x,y to the input inventory of the mover you send these signals to.



It works very well with a colored blueprint mod. If you send a colored blueprint signal in addition to a book to be copied to another book, the target book will contain all the blueprints of the start book, except that their color has changed. This can be used to transfer a book containing lots of different colored blueprints to a vanilla game. Example: If you set cc1 to redbook=-1, greenbp=1 and cc2 to bluebook=-1, you get a copy of your red book, which is a blue book and all blueprints in it are green. Can be used in-place (meaning in and output blueprints can agree, it will just change the color of all included blueprints to the desired one).

D=1(Delete): If this is active in cc1, it will delete the book after moving a copy to the desired location. This feature is not supported for single blueprints. Deleting a page in a book would cause inconsistencies. Deleting a single blueprint may be added in future.

PS: I would be quite surprised, if many people understood, how to use this. Please do not spam me with "I dont understand how this works."

PSS: I might add a working example in future, but im not sure.
