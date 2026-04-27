# Expense Manager Application Brief

## Purpose

Expense Manager is a Flutter application for tracking personal spending, organizing expenses by category and subcategory, reviewing spending analytics, managing income sources, and importing or exporting local finance data.

The app is built as a local-first personal finance tool. It stores user data on-device with Hive and provides a Material 3 interface with bottom navigation for the main workflows.

## Current Application Structure

The application starts in `lib/main.dart`. During startup it:

- Initializes Flutter bindings and Hive.
- Registers Hive adapters for `Expense`, `Category`, and `Income`.
- Opens three local Hive boxes: `categories`, `expenses`, and `incomes`.
- Creates default categories when the category box is empty.
- Launches a Material 3 app titled `Expense Manager`.

The main shell uses a bottom `NavigationBar` with five sections:

- Expenses
- Analytics
- Categories
- Profile
- Wallet

## Core Features

### Expense Tracking

The Expenses screen is the primary transaction list. It supports:

- Viewing saved expenses in reverse date order.
- Adding new expenses through a floating action button.
- Editing an expense by tapping an existing list item.
- Deleting expenses from the list.
- Searching by title, category, or subcategory.
- Filtering by date range.
- Filtering by category.
- Showing a default income amount from the Wallet data.
- Showing total spending for the current month.
- Showing filtered total spending when a category filter is active.

Expense entries include title, amount, date, category, subcategory, description, and the income source used.

### Add and Edit Expense

The Add Expense screen provides a form for creating or updating expenses. It supports:

- Required title.
- Required amount.
- Category selection.
- Subcategory selection when the chosen category has subcategories.
- Income source selection when wallet entries exist.
- Optional description.
- Date selection up to the current day.
- Preserving the existing expense ID when editing.

New expense IDs are generated from the current timestamp.

### Analytics

The Analytics screen summarizes spending from the saved expenses. It supports:

- Default view for the current month.
- Custom date range selection.
- Spending totals by category.
- Optional spending totals by subcategory.
- Toggle between pie chart and bar chart visualizations.
- Breakdown list with category or subcategory totals.
- Total spending for the active analytics range.

Charts are powered by `fl_chart`.

### Category Management

The Categories screen lets the user manage the expense taxonomy. It supports:

- Creating custom categories.
- Assigning an icon to each category.
- Setting an optional category budget.
- Adding subcategories to existing categories.
- Deleting subcategories.
- Deleting categories.
- Expanding categories to view their subcategories and actions.

Default categories are created on first launch:

- General
- Food
- Travel
- Shopping
- Bills

The bundled sample JSON also includes richer categories such as Entertainment, Loaning, Home, and Others.

### Wallet and Income Sources

The Wallet section is implemented by `IncomeScreen`. It supports:

- Adding income sources with an amount.
- Listing income sources.
- Marking one income source as default.
- Deleting income sources.

The default income source is used by the expense form and displayed in the Expenses summary area.

### Profile and Data Portability

The Profile screen focuses on import and export. It supports:

- Exporting data as JSON.
- Exporting expenses as CSV.
- Importing JSON or CSV files.
- Choosing import behavior:
  - Merge
  - Replace All
  - Skip Duplicates
- Showing import/export results through snackbars.

JSON export includes categories, expenses, and incomes. CSV export includes expenses only.

## Data Model

### Expense

Stored in Hive with `typeId: 0`.

Fields:

- `id`: unique expense identifier.
- `title`: expense name.
- `amount`: numeric amount.
- `date`: transaction date.
- `category`: category name.
- `subcategory`: subcategory name.
- `description`: optional notes.
- `fromIncomeSource`: optional income source name.

### Category

Stored in Hive with `typeId: 1`.

Fields:

- `name`: category name.
- `iconCode`: Material icon code point.
- `budget`: optional budget amount.
- `subcategories`: list of child category labels.

### Income

Stored in Hive with `typeId: 3`.

Fields:

- `source`: income source name.
- `amount`: income amount.
- `isDefault`: whether this income source is the default.

## Services

The project includes service classes for data access:

- `ExpenseService`: CRUD operations, date range filtering, category filtering, and income-source filtering.
- `CategoryService`: CRUD operations, lookup by name, and subcategory lookup.
- `IncomeService`: CRUD operations, total income calculation, and lookup by source.
- `FileService`: file picker integration, JSON import/export, CSV import/export, and duplicate detection for imported expenses.

Some screens currently access Hive boxes directly instead of consistently using the service classes.

## Import and Export Formats

### JSON

JSON import/export supports the full app data shape:

- `categories`
- `expenses`
- `incomes`

The bundled `assets/expense_data.json` contains:

- 9 categories
- 271 expenses
- 1 income source

### CSV

CSV import/export is expense-focused. The expected columns are:

- Title
- Amount
- Date
- Category
- Subcategory
- Description
- FromIncomeSource

The bundled `assets/expense_data.csv` includes expense rows and is useful as sample data for import testing.

## Technology Stack

- Flutter with Material 3 UI.
- Dart SDK constraint: `^3.8.1`.
- Hive and Hive Flutter for local persistence.
- Hive Generator and Build Runner for model adapters.
- `fl_chart` for analytics charts.
- `csv` for CSV parsing and generation.
- `file_picker` for selecting import files and export locations.
- `path_provider`, `permission_handler`, and `downloadsfolder` are included as dependencies, though the current file workflow primarily uses `file_picker`.

The project includes platform folders for Android, iOS, web, Windows, macOS, and Linux.

## User Workflows

### Add a New Expense

1. Open Expenses.
2. Tap the add button.
3. Enter title and amount.
4. Choose category and subcategory.
5. Choose the income source if available.
6. Optionally add a description.
7. Pick a date.
8. Save the expense.

### Review Spending

1. Open Analytics.
2. Use the date picker to choose a reporting period.
3. Toggle between category and subcategory grouping.
4. Toggle between pie chart and bar chart.
5. Review the breakdown list for exact totals.

### Manage Categories

1. Open Categories.
2. Tap the add button to show the category form.
3. Enter category name and optional budget.
4. Pick an icon.
5. Save the category.
6. Expand a category to add or remove subcategories.

### Import or Export Data

1. Open Profile.
2. Choose JSON or CSV export, or choose import.
3. For import, select a file and choose merge, replace, or skip-duplicates mode.
4. Review the snackbar result.

## Current Strengths

- Clear feature separation across bottom navigation tabs.
- Local-first data storage with no network dependency.
- Practical expense lifecycle: add, edit, delete, search, and filter.
- Useful analytics with both chart and list views.
- Customizable category and subcategory structure.
- Data portability through JSON and CSV.
- Sample asset data is available for testing imports and analytics.

## Current Gaps and Risks

- The README is still the default Flutter starter text and does not describe the app.
- Several source strings display mojibake for the rupee symbol, for example `â‚¹`, indicating an encoding issue in some files.
- Some null-safety assumptions can cause runtime errors, such as expecting a default income source when the income list is not empty.
- Category budgets are stored and displayed but are not yet used for alerts, progress, or budget comparisons.
- Income amounts are displayed and selected, but expenses do not currently subtract from income balances.
- The service layer exists, but screens often access Hive directly, so data logic is split between UI and service classes.
- CSV import only imports expenses; categories and incomes require JSON.
- Duplicate detection for imports uses title, amount, and date, which may skip distinct expenses that happen to share those values.
- There are debug `print` calls in application code.
- Test coverage appears limited to the default widget test scaffold.

## Suggested Next Improvements

- Replace the starter README with a user-facing and developer-facing project overview.
- Fix the rupee symbol encoding issue across Dart files.
- Harden income selection when no default income exists.
- Move repeated Hive access and filtering logic into services.
- Add budget tracking views that compare category budgets with actual spend.
- Add income balance summaries by income source.
- Add tests for import/export behavior, expense filtering, and analytics grouping.
- Consider a seeded data import path for the bundled sample assets.
