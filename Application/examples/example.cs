public static int Count<TSource>(this IEnumerable<TSource> source)
{
	// Comments
	if (source == null) throw Error.ArgumentNull("source");

	ICollection<TSource> collectionOfT = source as ICollection<TSource>;
	if (collectionOfT != null) return collectionOfT.Count;

	ICollection collection = source as ICollection;
	if (collection != null) return collection.Count;

	int count = 0;
	using (IEnumerator<TSource> e = source.GetEnumerator()) {
		checked {
			while (e.MoveNext()) count++;
		}
	}
	
	/*
	 multi line comment
	 */
	return count;
}
