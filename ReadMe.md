# SwipeSelection Beta ( ≥ iOS 9)

Explanation of the differnt folders in this repo.

```
Cydia Version: This directory contains the NEW SwipeSelection & SwipeSelection code we will be releasing.

Lupinus: This directory has your fork of the free SwipeSelection with the trackpad mode added.

SwipeSelection Xcode: This contains my experiement to run SwipeSelection on unjailbroken devices.

SwipeSelection: This is the SwipeSelection code for the version currently in Cydia.

SwipeSelection Pro: This is the SwipeSelection Pro code for the version currently in Cydia.
```

[Lupinus by GaryniL](https://github.com/GaryniL/SwipeSelection-Beta)


## TODO: Add SwipeSelection Features

Btw: The SwipeSelection code is a bit of a mess. I rewrote it and cleaned it up in SwipeSelection Pro. I only kept SwipeSelection the way it is for backwards compatibility with iOS 4 and 5. As this version won't need to support anything below iOS 9 we should base it on SwipeSelection Pro's code.


1. [x] Proof of concept

2. [x] Start selecting text when starting dragging from the shift or delete keys.
3. [ ] Don't trigger delete on touch down, only touch up or long press.
4. [ ] Don't trigger if the starting key is the 123 key, or world key.

5. [x] When selecting text pick the first cursor if the user begins the swipe going left, or up.
6. [x] When selecting pick the second cursor if the users swipe starts by going right, or down.
7. [ ] When selecting text, did it need to cancel previous select text range?

8. [ ] Look into how to make the keyboard change into the trackpad mode (-setDimmed: is not it)

9. [ ] Solve the problem conflicting with buildin version (only enable one at a time)


## Question 
- Todo 2: Please help me check if the recent version (0227) is same as SS
- Todo 3: Not really get what this means, but I implement it with method same as SS code on Github
- Todo 4: Is the world key means international keys? If it does, I finished.  
Yes, I said "world" key because iOS uses an icon of the globe for that key.

- Todo 5&6: Please check the recent version
- Todo 7: What do you think about this question?
- Todo 8: I tried to figure out how to make it, however, didn't find out. I think I will try to figure it out in future work.

## Progress
- 0227 Gary Finished selecting text with shift and delete key


-----


# Keyboard Behaviours

There are a few subtle keyboard behaviours I've added over time to SwipeSelection (added as people have complained I broke them).

**Quick Access to Numbers**

Using a latin based keyboard layout (English) you can tough down on the "123" key. The keyboard will instantly change to the numbers keyboard. If you keep your finger pressed down you can: swipe over, select a number, lift your finger and the keyboard will type that key and instantly return to the letters keyboard.  
This allows quick access to the numbers keyboard and so I disable SwipeSelection from starting if the user starts by touching the "more" key.

**Handwriting**

SwipeSelection breaks handwriting keyboards, used mostly by some asian languages. So it gets disabled if the keyboard is a handwriting keyboard.

**Viber**

The chat app "Viber" has (had?) a custom text view that crashes with SwipeSelection. So I diable it for that text view. `VBEmoticonsContentTextView`

**Emoji**

The Emoji keyboard is just a scroll view with emoji's listed. SwipeSelection used to trigger when you scrolled the emoji view (I can't remember how I fixed that).


# SwipeSelection Behaviour

As well as keyboard behaviour we need to avoid breaking there are some ways SwipeSelection changes the keyboard.

**Selection Keys**

Although the [original concept video](https://www.youtube.com/watch?v=RGQTaHGQ04Q) used only the shift key, it's useful on the iPhone to be able to drag from either side of the keyboard to select text (so the "shift", "delete" keys on English keyboard, and the "delete" and "ء" keys on Arabic? keyboards (I've forgotten what language I added that for).

**Moving the cursor**

When you move the cursor with SwipeSelection it should start from as far in the direction the user is going as possible.  
So if there is an existing select range when the user starts moving the cursor left we should pick the left most (the start point in English) position to start the cursor from and invalidate the existing selection range.  
If the user swipes down the bottom point of the selection should be taken as the starting point for the cursor to move from.

**Selection**

When you select text with SwipeSelection and there is an existing select range it should follow a similar pattern as when moving the cursor, except it extends the existing selection range.  
So if the user swipes down the bottom point of the existing selection range will be the part that moves, leaving the upper start point where it is.

