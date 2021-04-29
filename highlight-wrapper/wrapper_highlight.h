#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCUnusedGlobalDeclarationInspection"
#ifndef WRAPPER_HIGHLIGHT_H
#define WRAPPER_HIGHLIGHT_H

#define EXPORT __attribute__((visibility("default")))

#ifdef __cplusplus
extern "C" {
#endif

/*!
 * Info about a theme.
 */
typedef struct HThemeInfo {
    char *name;
    char *desc;
    char *path; /*!< Full path of the theme file. */
    int base16;
    int appearance;
} HThemeInfo;

/*!
 * Info about a plugin.
 */
typedef struct HPluginInfo {
    char *name;
    char *desc;
    char *path; /*!< Full path of the theme file. */
} HPluginInfo;

/*!
 * Single property of a theme.
 */
typedef struct HThemeProperty {
    char *color;
    int bold; /*!< 0: false, 1: true, -1: not defined */
    int italic;
    int underline;
    int numberOfCustomStyles;
    char **formats;
    char **styles;
    int *override;
} HThemeProperty;

enum HThemeAppearance { not_set = 0, light = 1, dark = 2 };

/*!
 * HTheme.
 */
typedef struct HTheme {
    char *name;
    char *desc;
    char *path;
    enum HThemeAppearance appearance;
    int standalone;
    int base16;

    HThemeProperty *plain;
    HThemeProperty *canvas;
    HThemeProperty *number;
    HThemeProperty *string;
    HThemeProperty *escape;
    HThemeProperty *preProcessor;
    HThemeProperty *stringPreProc;
    HThemeProperty *blockComment;
    HThemeProperty *lineComment;
    HThemeProperty *lineNum;
    HThemeProperty *operatorProp;
    HThemeProperty *interpolation;

    HThemeProperty *hover;
    HThemeProperty *error;
    HThemeProperty *errorMessage;
    
    HThemeProperty *lspType;
    HThemeProperty *lspClass;
    HThemeProperty *lspStruct;
    HThemeProperty *lspInterface;
    HThemeProperty *lspParameter;
    HThemeProperty *lspVariable;
    HThemeProperty *lspEnumMember;
    HThemeProperty *lspFunction;
    HThemeProperty *lspMethod;
    HThemeProperty *lspKeyword;
    HThemeProperty *lspNumber;
    HThemeProperty *lspRegexp;
    HThemeProperty *lspOperator;

    int keyword_count;
    HThemeProperty **keywords;
} HTheme;

typedef void (*ResultCallback)( void* context, const char* result, int error);
/*!
 * Callback function to handle the result of highlight_list_themes.
 *
 * @see highlight_list_themes
 */
typedef void (*ResultThemeListCallback)(void* context, const HThemeInfo **themes, int count, int exit_code);

typedef void (*ResultPluginListCallback)(void* context, const HPluginInfo **plugins, int count, int exit_code);

typedef void (* ReleaseTheme)(HTheme *theme);
typedef void (* ReleaseThemeInfo)(HThemeInfo *theme);
typedef void (* ReleaseThemeInfoList)(HThemeInfo **themes, int count);
typedef void (* ReleasePluginInfoList)(HPluginInfo **plugins, int count);

/*!
 * Callback function to handle the request of a theme info.
 * @see highlight_theme_info
 */
typedef void (*ResultThemeCallback)(void* context, const HTheme *theme, int exit_code);

EXPORT char *get_highlight_version(void);
EXPORT char *get_highlight_website(void);
EXPORT char *get_highlight_email(void);
/*!
 *
 * @return The formatted highlight info. *User must release the data.*
 */
EXPORT char *get_highlight_about(void);

EXPORT const char *get_lua_info(void);

EXPORT int highlight_is_initialized(void);

/*!
 * Initialize the highlight context with the provided path.
 * This function must be always called one time before all others.
 * @param search_dir Path of folder that contain filetypes.conf file and the directories langDefs, themes, plugins.
 *
 * @see highlight_init_generator
 */
EXPORT void highlight_init(const char *search_dir);

/*!
 * Init the generator.
 * Previous initialized generator is released.
 * @return EXIT_SUCCESS or EXIT_FAILURE
 *
 * @see highlight_release_generator
 */
int highlight_init_generator(void);

/*!
 * Free the memory used by the generator if no more rendering is required.
 */
EXPORT void highlight_release_generator(void);

/*!
 * Get the CSS style code.
 * @param context Custom context to pass to the callback.
 * @param callback Callback that receive the formatted code.
 * @param background Override the background color.
 * Pass NULL to do not override, an empty string remove the color, other value is used as new color.
 *
 * @see highlight_format_style2
 */
EXPORT void highlight_format_style(void *context, ResultCallback callback, const char *background);

/*!
 * Get the CSS style code.
 * @param exit_code EXIT_SUCCESS if no error.
 * @param background Override the background color.
 * Pass NULL to do not override, an empty string remove the color, other value is used as new color.
 * @return The formatted code. **You are responsible for the memory deallocation**.
 *
 * @see highlight_format_style
 */
EXPORT char *highlight_format_style2(int *exit_code, const char *background);

/*!
 * Get a list of the predefined themes.
 * @param context Custom context to pass to the callback.
 * @param callback Callback to pass the theme list.
 * @return EXIT_SUCCESS on success.
 *
 * @see highlight_list_themes2
 */
EXPORT int highlight_list_themes( void *context, ResultThemeListCallback callback);

/*!
 * Get a list of the predefined themes.
 * @param theme_list List of detected themes.
 * @param count Number of themes.
 * @param release Function to call to release the theme list. **You must release the memory with the function received in the release argument.**
 * @return EXIT_SUCCESS if no error.
 *
 * @see highlight_list_themes
 */
EXPORT int highlight_list_themes2(HThemeInfo ***theme_list, int *count, ReleaseThemeInfoList *release);

/*!
 * Get the properties of a theme.
 * @param theme Name of the theme or the full path.
 * @param context Custom context to pass to the callback.
 * @param callback Callback that receive the formatted code.
 * @return EXIT_SUCCESS on success.
 */
EXPORT int highlight_get_theme( const char *theme, void *context, ResultThemeCallback callback);
/*!
 * Get the properties of a theme.
 * @param theme Name of the theme or the full path.
 * @param exit_code EXIT_SUCCESS if no error.
 * @param release Function to call to release the returned value.
 * @return The theme info. **You must release the memory with the function received in the release argument.**
 */
EXPORT HTheme *highlight_get_theme2(const char *theme, int *exit_code, ReleaseTheme *release);

/*!
 * Store the theme inside a file.
 * @param filename Destination file name.
 * @param theme HTheme to store.
 * @return EXIT_SUCCESS on success.
 */
EXPORT int highlight_save_theme( const char *filename, const HTheme *theme);

/*!
 * Get a list of the predefined plugins.
 * @param context Custom context to pass to the callback.
 * @param callback Callback to pass the theme list.
 * @return EXIT_SUCCESS on success.
 *
 * @see highlight_list_plugins2
 */
EXPORT int highlight_list_plugins( void *context, ResultPluginListCallback callback);

/*!
 * Get a list of the predefined plugins.
 * @param plugin_list List of detected plugins.
 * @param count Number of plugins.
 * @param release Function to call to release the plugins list. **You must release the memory with the function received in the release argument.**
 * @return EXIT_SUCCESS if no error.
 *
 * @see highlight_list_plugins
 */
EXPORT int highlight_list_plugins2(HPluginInfo ***plugin_list, int *count, ReleasePluginInfoList *release);

typedef struct {
    const char *name;
    const char **extensions;
    int n;
} lang_def;

typedef void (*LanguageCallback)( void* context, int i, lang_def lang);

/*!
 * Get all supported languages.
 * @param context Custom context to pass to the callback.
 * @param callback Callback to pass the theme list.
 * @return Number of supported languages or -1 in case of error.
 */
EXPORT int highlight_get_supported_languages(void* context, LanguageCallback callback);

/**
 * Check if a file is supported.
 * @param filename Path of the file to check.
 * @return The recognized language or NULL in case of error. *User must release the data.*
 */
EXPORT char *highlight_is_file_supported(const char *filename);

/*!
 * Check if a extension is supported.
 * @param extension Extension to check (without dot prefix).
 * @return The recognized language or NULL in case of error. *User must release the data.*
 */
EXPORT char *highlight_is_extension_supported(const char *extension);

#ifdef __cplusplus
}
#endif

#endif
#pragma clang diagnostic pop
