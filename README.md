# SortBags (Turtle WoW Edition)

**Turbo-charged, Lag-Resistant Bag Sorter for WoW 1.12.1**

> [!IMPORTANT]
> **SuperWoW is Mandatory**: This addon utilizes the high-precision `debugprofilestop()` API provided by [SuperWoW](https://github.com/balakethelock/SuperWoW) to manage the Burst Engine frame budget and performance metrics. Without it, the addon may not function at peak performance.

## Features

*   **⚡ Burst Engine**: Sorts 100+ items in seconds using a 10ms frame budget.
*   **🛡️ Lag-Proof**:
    *   **Smart Lookahead**: Skips over locked ("grey") slots instantly, continuing to sort other items.
    *   **Retry Queue**: Handles server lag spikes without stopping or crashing.
    *   **Sync Verify**: Strict ID checking prevents item loss or corruption during movement.
*   **🎒 Intelligent Logic**:
    *   **Special Bags**: Automatically fills Soul, Herb, Enchanting, and Ammo bags first.
    *   **Overflow Handling**: If special bags are full, remaining items are grouped at the *end* of your normal bags (closest to the special bag).
    *   **Smart Swap**: Swaps items directly (A <-> B) instead of moving them to empty slots first.
*   **🧊 Freeze Mode**: Alt+Click any item to "Freeze" it (it will never be moved by the sorter).
*   **🌍 Multi-Language**: English, German, Spanish, Chinese, Ukrainian.

## Installation

1.  Download the **SortBags** folder.
2.  Install [SuperWoW](https://github.com/balakethelock/SuperWoW) (Required).
3.  Place **SortBags** in `WoW/Interface/AddOns/`.

## Usage

*   **/sb** or **/sortbags** - Sort Inventory.
*   **/sb bank** - Sort Bank (Bank window must be open!).
*   **Alt + Click** on an item - Toggle Freeze (Lock/Unlock).

## Configuration

No GUI needed. The addon creates a `SortBags_IgnoreList` in your `SavedVariables` per character to remember frozen items.

## Credits & Thanks

*   **Original Author**: shirsig (The legend of Vanilla addons).
*   **Refactoring & Optimization**: Unsoul.
*   **Inspiration**:
    *   **Shagu (pfUI)**: For setting the standard on optimized Lua 5.0 code and efficient frame handling.
    *   **SuperWoW Team**: For extending the Vanilla API limits.

## For Developers

See `SortBags_Technical_Reference.md` for a deep dive into the Burst Engine, Transactional Queue, and Lua 5.0 optimizations used in this project.
