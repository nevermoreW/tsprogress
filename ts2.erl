-module(ts2).
-export([new/0,in/2,out/2,tuplespace/2,find/2, delete/2]).

%Tuplespace
tuplespace(CurrentList,QueueList) ->
     receive
          {From, Ref, Pattern, takeout} ->
               case find(CurrentList, Pattern) of
	            {found,Pattern} ->
		         NewList= delete(CurrentList,Pattern),
		         NewQueueList=QueueList,
		         From ! {Pattern, Ref};
		    {not_found,Pattern} ->
		         NewQueueList= QueueList ++[{Pattern, From, Ref}],
		         NewList=CurrentList;
                    true ->
		         NewList=CurrentList,
		         NewQueueList=QueueList
	       end;
           {From, Ref, Pattern, putin} ->
                L=lists:keytake(Pattern, 1, QueueList),
		case L of
		     {value, ExtractedElement, NewQueueList} ->  
			   element(2,ExtractedElement) ! {element(1,ExtractedElement),element(3,ExtractedElement)},
			   NewList=CurrentList;
		     false ->
			   NewList = [Pattern|CurrentList],
			   NewQueueList = QueueList
                end,
		From! {Pattern,Ref};
	   true ->
	        NewList = CurrentList,
		NewQueueList = QueueList
       end,
tuplespace(NewList,NewQueueList).

delete([First|Rest],A) ->
     if
          First==A ->
               Rest;
                                true ->
                                     [First|delete(Rest,A)]
                       end;

delete([],A) ->
             [].
find([First|Rest], A) ->
                   if
                        First == A ->
                              {found, A};
                        true ->
                             find(Rest,A)
                        end;
find([],A) ->
{not_found,A}.


%Returns the PID of a new tuplespace (the server)
new() ->
spawn_link(ts,tuplespace,[[],[]])
%io:format("~w tuplespace created~n",[L])


.
% Wants to take out pattern into TS. Should block if the element Pattern
% is not already in TS.
in(TS,Pattern) ->
Ref = make_ref(),
TS ! {self(),Ref, Pattern, takeout},
receive
	{Pattern, Ref} ->
	          io:format("~w received ~w with reference ~w from ~w~n",[self(),Pattern, Ref,TS]),
		  Pattern;
         true ->
	      io:format("Error in Pattern or reference received~n",[])
	     end
.

% Wants to put in pattern from TS.
out(TS, Pattern) ->
Ref = make_ref(),
TS ! {self(), Ref, Pattern, putin},
receive
       {Pattern, Ref} ->
               io:format("~w successfully gave ~w to ~w with reference:~w~n ",[self(), Pattern, TS, Ref]);
       true ->
       io:format("Some wrong happened :(", [])
       end.