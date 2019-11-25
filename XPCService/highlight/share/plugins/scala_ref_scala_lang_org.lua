--[[
Sample plugin file for highlight 3.9

-- to be finished---
]]

Description="Add scala-lang.org reference links to HTML, LaTeX, RTF and ODT output of Scala code"

Categories = {"scala", "html", "rtf", "latex", "odt" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if desc~="Scala" then
    return
  end

  function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
      return set
  end

  scala_items = Set
  { "Any","AnyRef","AnyVal","App","Application","Array","Boolean","Byte","Cell",
    "Char","cloneable","Console","CountedIterator","DelayedInit","deprecated",
    "deprecatedName","Double","Dynamic","Either","Enumeration","Equals",
    "FallbackArrayBuilding","Float","Function","Function1","Function2","Immutable",
    "inline","Int","Left","Long","LowPriorityImplicits","MatchError","Math",
    "Mutable","native","noinline","None","NotDefinedError","Nothing","NotNull",
    "Null","Option","PartialFunction","Predef","Product","Product1","Product2",
    "Proxy","remote","Responder","Right","Serializable","SerialVersionUID","Short",
    "Some","specialized","Symbol","throws","transient","Tuple1","Tuple2","unchecked",
    "UninitializedError","UninitializedFieldError","Unit","volatile" }


  actor_items = Set
  { "AbstractActor","Actor","CanReply","Channel","DaemonActor","Debug","Exit",
    "Future","Futures","InputChannel","IScheduler","MessageQueue",
    "MessageQueueElement","OutputChannel","Reaction","Reactor","ReplyReactor",
    "Scheduler","SchedulerAdapter","TIMEOUT","UncaughtException" }

  remote_items = Set
  { "ExitFun","FreshNameCreator","JavaSerializer","LinkToFun","LocalApply0",
    "Locator","NamedSend","Node","RemoteActor","RemoteApply0","SendTo","Serializer",
    "Service","TcpService","Terminate","UnlinkFromFun" }

  actors_scheduler_items = Set
  { "ActorGC","DaemonScheduler","ExecutorScheduler","ForkJoinScheduler",
    "ResizableThreadPoolScheduler","SingleThreadedScheduler" }

  annotation_items = Set
  { "Annotation","ClassfileAnnotation","elidable","implicitNotFound","serializable",
    "StaticAnnotation","strictfp","switch","tailrec","TypeConstraint","varargs" }

  annotation_target_items = Set
  { "beanGetter","beanSetter","field","getter","param","setter" }


  annotation_unchecked_items= Set
  { "uncheckedStable","uncheckedVariance" }


  collection_items= Set
  { "BitSet","BitSetLike","BufferedIterator","CustomParallelizable","DefaultMap",
    "GenIterable","GenIterableLike","GenIterableView","GenIterableViewLike","GenMap",
    "GenMapLike","GenSeq","GenSeqLike","GenSeqView","GenSeqViewLike","GenSet",
    "GenSetLike","GenTraversable","GenTraversableLike","GenTraversableOnce",
    "GenTraversableView","GenTraversableViewLike","IndexedSeq","IndexedSeqLike",
    "IndexedSeqOptimized","Iterable","IterableLike","IterableProxy",
    "IterableProxyLike","IterableView","IterableViewLike","Iterator",
    "JavaConversions","JavaConverters","LinearSeq","LinearSeqLike",
    "LinearSeqOptimized","Map","MapLike","MapProxy","MapProxyLike","Parallel",
    "Parallelizable","Seq","SeqLike","SeqProxy","SeqProxyLike","SeqView",
    "SeqViewLike","Set","SetLike","SetProxy","SetProxyLike","SortedMap",
    "SortedMapLike","SortedSet","SortedSetLike","Traversable","TraversableLike",
    "TraversableOnce","TraversableProxy","TraversableProxyLike","TraversableView",
    "TraversableViewLike","ViewMkString","focushide" }


  collection_generic_items= Set
  { "Addable","AtomicIndexFlag","BitSetFactory","CanBuildFrom","CanCombineFrom",
    "ClassManifestTraversableFactory","DefaultSignalling","DelegatedContext",
    "DelegatedSignalling","FilterMonadic","GenericClassManifestCompanion",
    "GenericClassManifestTraversableTemplate","GenericCompanion",
    "GenericOrderedCompanion","GenericOrderedTraversableTemplate",
    "GenericParCompanion","GenericParMapCompanion","GenericParMapTemplate",
    "GenericParTemplate","GenericSeqCompanion","GenericSetTemplate",
    "GenericTraversableTemplate","GenMapFactory","GenSeqFactory","GenSetFactory",
    "GenTraversableFactory","Growable","HasNewBuilder","HasNewCombiner",
    "IdleSignalling","ImmutableMapFactory","ImmutableSetFactory",
    "ImmutableSortedMapFactory","ImmutableSortedSetFactory","IterableForwarder",
    "MapFactory","MutableMapFactory","MutableSetFactory","OrderedTraversableFactory",
    "ParFactory","ParMapFactory","ParSetFactory","SeqFactory","SeqForwarder",
    "SetFactory","Shrinkable","Signalling","Sizing","SliceInterval","Sorted",
    "SortedMapFactory","SortedSetFactory","Subtractable","TaggedDelegatedContext",
    "TraversableFactory","TraversableForwarder","VolatileAbort" }

  collection_immutable_items= Set
  { "BitSet","DefaultMap","HashMap","HashSet","IndexedSeq","IntMap","Iterable",
    "LinearSeq","List","ListMap","ListSet","LongMap","Map","MapLike","MapProxy",
    "Nil","NumericRange","RangeUtils","PagedSeq","Queue","Range","RedBlack","Seq",
    "Set","SetProxy","SortedMap","SortedSet","Stack","Stream","StreamIterator",
    "StreamView","StreamViewLike","StringLike","StringOps","Traversable","TreeMap",
    "TreeSet","Vector","VectorBuilder","VectorIterator","WrappedString" }


  collection_interfaces_items= Set
  { "IterableMethods","MapMethods","SeqMethods","SetMethods","SubtractableMethods",
    "TraversableMethods","TraversableOnceMethods" }


  collection_mutable_items= Set
  { "AddingBuilder","ArrayBuffer","ArrayBuilder","ArrayLike","ArrayOps","ArraySeq",
    "ArrayStack","BitSet","Buffer","BufferLike","BufferProxy","Builder","Cloneable",
    "ConcurrentMap","DefaultEntry","DefaultMapModel","DoubleLinkedList",
    "DoubleLinkedListLike","FlatHashTable","GrowingBuilder","HashEntry","HashMap",
    "HashSet","HashTable","History","ImmutableMapAdaptor","ImmutableSetAdaptor",
    "IndexedSeq","IndexedSeqLike","IndexedSeqOptimized","IndexedSeqView","Iterable",
    "LazyBuilder","LinearSeq","LinkedEntry","LinkedHashMap","LinkedHashSet",
    "LinkedList","LinkedListLike","ListBuffer","ListMap","Map","MapBuilder",
    "MapLike","MapProxy","MultiMap","MutableList","ObservableBuffer","ObservableMap",
    "ObservableSet","OpenHashMap","PriorityQueue","PriorityQueueProxy","Publisher",
    "Queue","QueueProxy","ResizableArray","RevertibleHistory","Seq","SeqLike","Set",
    "SetBuilder","SetLike","SetProxy","Stack","StackProxy","StringBuilder",
    "Subscriber","SynchronizedBuffer","SynchronizedMap","SynchronizedPriorityQueue",
    "SynchronizedQueue","SynchronizedSet","SynchronizedStack","Traversable",
    "Undoable","UnrolledBuffer","WeakHashMap","WrappedArray","WrappedArrayBuilder" }


  collection_parallel_items= Set
  { "AdaptiveWorkStealingForkJoinTasks","AdaptiveWorkStealingTasks",
    "AdaptiveWorkStealingThreadPoolTasks","Combiner","ForkJoinTasks",
    "FutureThreadPoolTasks","HavingForkJoinPool","IterableSplitter",
    "CompositeThrowable","FactoryOps","ThrowableOps","TraversableOps","ParIterable",
    "ParIterableLike","ParIterableView","ParIterableViewLike","ParMap","ParMapLike",
    "ParSeq","ParSeqLike","ParSeqView","ParSeqViewLike","ParSet","ParSetLike",
    "PreciseSplitter","SeqSplitter","Splitter","Tasks","TaskSupport",
    "ThreadPoolTasks" }


  collection_parallel_immutable_items= Set
  { "Builder","HashSetCombiner","ParHashMap","ParHashSet","ParIterable","ParMap",
    "ParRange","ParSeq","ParSet","ParVector" }

  collection_parallel_mutable_items= Set
  { "LazyCombiner","ParArray","ParFlatHashTable","ParHashMap","ParHashSet",
    "ParHashTable","ParIterable","ParMap","ParMapLike","ParSeq","ParSet",
    "ParSetLike","ResizableParArrayCombiner","UnrolledParArrayCombiner" }

  function getURL(token, cat)
    url='http://www.scala-lang.org/api/current/scala/'..cat..'/'..token.. '.html'

    if (HL_OUTPUT== HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
      return '<a class="hl" target="new" href="' .. url .. '">'.. token .. '</a>'
    elseif (HL_OUTPUT == HL_FORMAT_LATEX) then
      return '\\href{'..url..'}{'..token..'}'
    elseif (HL_OUTPUT == HL_FORMAT_RTF) then
      return '{{\\field{\\*\\fldinst HYPERLINK "'..url..'" }{\\fldrslt\\ul\\ulc0 '..token..'}}}'
    elseif (HL_OUTPUT == HL_FORMAT_ODT) then
      return '<text:a xlink:type="simple" xlink:href="'..url..'">'..token..'</text:a>'
    end
  end


  function Decorate(token, state)

    if (state ~= HL_STANDARD and state ~= HL_KEYWORD) then
      return
    end

    if scala_items[token] then
      return getURL(token, '')
    elseif  actor_items[token] then
      return getURL(token, 'actors')
    elseif  remote_items[token] then
      return getURL(token, 'remote')
    elseif  actors_scheduler_items[token] then
      return getURL(token, 'actors/scheduler')
    elseif  annotation_items[token] then
      return getURL(token, 'annotation')
    elseif  annotation_target_items[token] then
      return getURL(token, 'annotation/target')
    elseif  annotation_unchecked_items[token] then
      return getURL(token, 'annotation/unchecked')
    elseif  collection_items[token] then
      return getURL(token, 'collection')
    elseif  collection_generic_items[token] then
      return getURL(token, 'collection/generic')
    elseif  collection_immutable_items[token] then
      return getURL(token, 'collection/immutable')
    elseif  collection_interfaces_items[token] then
      return getURL(token, 'collection/interfaces')
    elseif  collection_mutable_items[token] then
      return getURL(token, 'collection/mutable')
    elseif  collection_parallel_items[token] then
      return getURL(token, 'collection/parallel')
    elseif  collection_parallel_immutable_items[token] then
      return getURL(token, 'collection/parallel/immutable')
    elseif  collection_parallel_mutable_items[token] then
      return getURL(token, 'collection/parallel/mutable')
    end

  end
end

function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]="a.hl, a.hl:visited {color:inherit;font-weight:inherit;}"
  elseif (HL_OUTPUT==HL_FORMAT_LATEX) then
    Injections[#Injections+1]="\\usepackage[colorlinks=false, pdfborderstyle={/S/U/W 1}]{hyperref}"
  end
end

--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },

}
