import { useEffect, useMemo, useState } from 'react'
import type { FormEvent } from 'react'
import {
  addDoc, collection, deleteDoc, doc, getDoc, onSnapshot,
  orderBy, query, serverTimestamp, updateDoc, where,
} from 'firebase/firestore'
import {
  onAuthStateChanged, signInWithEmailAndPassword, signOut,
} from 'firebase/auth'
import type { User } from 'firebase/auth'
import {
  Activity, Bell, CalendarDays, FileText, LogOut, Plus, RefreshCw,
  Search, ShieldCheck, Trash2, Users, X, LayoutDashboard, Pencil,
} from 'lucide-react'
import { auth, db } from './firebase'

type Section = 'overview' | 'announcements' | 'speakers' | 'sessions' | 'conference'
type RecordItem = { id: string; [key: string]: unknown }

const sections: { id: Section; label: string; icon: typeof LayoutDashboard }[] = [
  { id: 'overview', label: 'Overview', icon: LayoutDashboard },
  { id: 'announcements', label: 'Announcements', icon: Bell },
  { id: 'speakers', label: 'Speakers', icon: Users },
  { id: 'sessions', label: 'Programme', icon: CalendarDays },
  { id: 'conference', label: 'Conference Info', icon: FileText },
]

const configs = {
  announcements: {
    title: 'Announcements', collection: 'announcements',
    fields: [
      { key: 'title', label: 'Title', type: 'text' },
      { key: 'message', label: 'Message', type: 'textarea' },
    ],
  },
  speakers: {
    title: 'Speakers', collection: 'speakers',
    fields: [
      { key: 'name', label: 'Full name', type: 'text' },
      { key: 'designation', label: 'Designation', type: 'text' },
      { key: 'category', label: 'Category (Keynote / Invited / Technical)', type: 'text' },
      { key: 'affiliation', label: 'Organisation / University', type: 'text' },
      { key: 'bio', label: 'Biography', type: 'textarea' },
      { key: 'photoUrl', label: 'Photo URL (optional)', type: 'url' },
    ],
  },
  sessions: {
    title: 'Programme Sessions', collection: 'sessions',
    fields: [
      { key: 'title', label: 'Session title', type: 'text' },
      { key: 'date', label: 'Date (e.g. 14 January 2027)', type: 'text' },
      { key: 'startTime', label: 'Start time', type: 'text' },
      { key: 'endTime', label: 'End time', type: 'text' },
      { key: 'venue', label: 'Room / Venue', type: 'text' },
      { key: 'description', label: 'Description', type: 'textarea' },
    ],
  },
} as const

type ManagedSection = keyof typeof configs

export default function App() {
  const [user, setUser] = useState<User | null>(null)
  const [authLoading, setAuthLoading] = useState(true)
  const [admin, setAdmin] = useState(false)
  const [checkingAdmin, setCheckingAdmin] = useState(false)
  const [section, setSection] = useState<Section>('overview')
  const [items, setItems] = useState<RecordItem[]>([])
  const [conference, setConference] = useState<Record<string, unknown> | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')
  const [search, setSearch] = useState('')
  const [modal, setModal] = useState<ManagedSection | 'conference' | null>(null)
  const [editing, setEditing] = useState<RecordItem | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => onAuthStateChanged(auth, async current => {
    setUser(current)
    setAdmin(false)
    setAuthLoading(false)
    if (!current) return
    setCheckingAdmin(true)
    try {
      const snap = await getDoc(doc(db, 'admins', current.uid))
      setAdmin(snap.exists() && snap.data().active === true)
    } catch (e) {
      setError(messageOf(e))
    } finally {
      setCheckingAdmin(false)
    }
  }), [])

  useEffect(() => {
    if (!user || !admin) return
    if (section === 'conference') {
      setLoading(true)
      return onSnapshot(doc(db, 'conference_info', 'main'), snap => {
        setConference(snap.exists() ? snap.data() : {})
        setLoading(false)
      }, e => { setError(messageOf(e)); setLoading(false) })
    }
    if (section === 'overview') {
      setLoading(true)
      let completed = 0
      const counts: Record<string, number> = {}
      const stops = ['announcements', 'speakers', 'sessions'].map(name =>
        onSnapshot(query(collection(db, name), where('isPublished', '==', true)), snap => {
          counts[name] = snap.size
          completed++
          if (completed >= 3) { setItems(Object.entries(counts).map(([id, count]) => ({ id, count }))); setLoading(false) }
        }, e => { setError(messageOf(e)); setLoading(false) })
      )
      return () => stops.forEach(stop => stop())
    }
    const name = configs[section as ManagedSection].collection
    setLoading(true)
    const q = section === 'announcements'
      ? query(collection(db, name), orderBy('createdAt', 'desc'))
      : query(collection(db, name))
    return onSnapshot(q, snap => {
      setItems(snap.docs.map(d => ({ id: d.id, ...d.data() })))
      setLoading(false)
    }, e => { setError(messageOf(e)); setLoading(false) })
  }, [user, admin, section])

  const filteredItems = useMemo(() => items.filter(item =>
    JSON.stringify(item).toLowerCase().includes(search.toLowerCase())
  ), [items, search])

  async function saveRecord(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!modal) return
    const form = new FormData(event.currentTarget)
    const data: Record<string, unknown> = {}
    if (modal === 'conference') {
      for (const key of ['title', 'conferenceName', 'venue', 'startDate', 'endDate', 'website', 'ieeeRecordNumber']) {
        data[key] = String(form.get(key) ?? '').trim()
      }
      data.isPublished = true
      setSaving(true)
      try {
        await updateDoc(doc(db, 'conference_info', 'main'), data)
        setNotice('Conference information updated.')
        setModal(null)
      } catch (e) { setError(messageOf(e)) } finally { setSaving(false) }
      return
    }
    const cfg = configs[modal]
    for (const field of cfg.fields) data[field.key] = String(form.get(field.key) ?? '').trim()
    data.isPublished = form.get('isPublished') === 'on'
    if (modal === 'announcements' && !editing) data.createdAt = serverTimestamp()
    setSaving(true)
    try {
      if (editing) await updateDoc(doc(db, cfg.collection, editing.id), data)
      else await addDoc(collection(db, cfg.collection), data)
      setNotice(`${cfg.title} ${editing ? 'updated' : 'added'} successfully.`)
      setModal(null); setEditing(null)
    } catch (e) { setError(messageOf(e)) } finally { setSaving(false) }
  }

  async function removeRecord(kind: ManagedSection, item: RecordItem) {
    if (!window.confirm(`Delete "${String(item.title ?? item.name ?? 'this record')}"?`)) return
    try {
      await deleteDoc(doc(db, configs[kind].collection, item.id))
      setNotice('Record deleted.')
    } catch (e) { setError(messageOf(e)) }
  }

  async function saveConference(event: FormEvent<HTMLFormElement>) { await saveRecord(event) }

  if (authLoading || checkingAdmin) return <div className="center-screen"><div className="loader" />Checking administrator access…</div>
  if (!user) return <Login onLogin={async (email, password) => {
    setError('')
    await signInWithEmailAndPassword(auth, email, password)
  }} error={error} />
  if (!admin) return <div className="center-screen"><div className="access-card"><ShieldCheck size={38}/><h2>Administrator access required</h2><p>This account is not marked as an active ICSC 2027 administrator in Firestore.</p><button className="button secondary" onClick={() => signOut(auth)}>Sign out</button></div></div>

  const title = section === 'overview' ? 'Dashboard overview' : section === 'conference' ? 'Conference information' : configs[section as ManagedSection].title

  return <div className="app-shell">
    <aside className="sidebar">
      <div className="brand"><div className="brand-mark">IC</div><div><strong>ICSC 2027</strong><small>ADMIN CONSOLE</small></div></div>
      <div className="side-label">WORKSPACE</div>
      <nav>{sections.map(s => <button key={s.id} className={`nav-item ${section === s.id ? 'active' : ''}`} onClick={() => { setSection(s.id); setSearch(''); setError(''); }}><s.icon size={18}/>{s.label}</button>)}</nav>
      <div className="sidebar-bottom"><div className="secure"><ShieldCheck size={16}/> Secure admin session</div><button className="nav-item logout" onClick={() => signOut(auth)}><LogOut size={18}/> Sign out</button></div>
    </aside>
    <main className="main-area">
      <header className="topbar"><div><span className="eyebrow">ICSC 2027 / ADMIN</span><h1>{title}</h1></div><div className="user-pill"><span className="avatar">{(user.email ?? 'A').slice(0,1).toUpperCase()}</span><span>{user.email}</span></div></header>
      <div className="content">
        {error && <div className="alert error"><span>{error}</span><button onClick={() => setError('')}><X size={16}/></button></div>}
        {notice && <div className="alert success"><span>{notice}</span><button onClick={() => setNotice('')}><X size={16}/></button></div>}
        {section === 'overview' && <><div className="welcome"><div><span className="eyebrow light">CONFERENCE MANAGEMENT</span><h2>Good to see you.</h2><p>Manage the information attendees see in the ICSC 2027 mobile app.</p></div><Activity size={54}/></div><div className="stats-grid">{items.map(item => <div className="stat-card" key={item.id}><span>{item.id}</span><strong>{String(item.count ?? 0)}</strong><small>Published records</small></div>)}</div><div className="panel"><div className="panel-heading"><div><h3>Quick actions</h3><p>Update conference content</p></div></div><div className="quick-grid"><button onClick={() => {setEditing(null);setModal('announcements')}}><Plus/> New announcement</button><button onClick={() => {setEditing(null);setModal('speakers')}}><Plus/> Add speaker</button><button onClick={() => {setEditing(null);setModal('sessions')}}><Plus/> Add programme session</button></div></div></>}
        {section !== 'overview' && section !== 'conference' && <div className="panel"><div className="panel-heading"><div><h3>{title}</h3><p>Changes are saved directly to Cloud Firestore.</p></div><button className="button primary" onClick={() => {setEditing(null);setModal(section as ManagedSection)}}><Plus size={17}/> Add new</button></div><div className="toolbar"><div className="search"><Search size={17}/><input value={search} onChange={e => setSearch(e.target.value)} placeholder={`Search ${title.toLowerCase()}…`}/></div><button className="icon-button" onClick={() => setSearch('')} title="Clear search"><RefreshCw size={17}/></button></div>{loading ? <p className="empty">Loading records…</p> : filteredItems.length === 0 ? <p className="empty">No records yet. Use “Add new” to create the first one.</p> : <div className="record-list">{filteredItems.map(item => <div className="record" key={item.id}><div className="record-main"><strong>{String(item.title ?? item.name ?? 'Untitled record')}</strong><p>{String(item.message ?? item.affiliation ?? item.date ?? item.description ?? '')}</p><span className={`status ${item.isPublished === false ? 'draft' : ''}`}>{item.isPublished === false ? 'Draft' : 'Published'}</span></div><div className="record-actions"><button className="icon-button" title="Edit" onClick={() => {setEditing(item);setModal(section as ManagedSection)}}><Pencil size={17}/></button><button className="icon-button danger" title="Delete" onClick={() => removeRecord(section as ManagedSection, item)}><Trash2 size={17}/></button></div></div>)}</div>}</div>}
        {section === 'conference' && <div className="panel"><div className="panel-heading"><div><h3>Public conference details</h3><p>These values are read by the Flutter home screen.</p></div><button className="button primary" onClick={() => {setEditing(null);setModal('conference')}}><Pencil size={17}/> Edit details</button></div>{loading ? <p className="empty">Loading…</p> : <div className="details-grid">{[['Title','title'],['Conference name','conferenceName'],['Venue','venue'],['Start date','startDate'],['End date','endDate'],['Website','website'],['IEEE record number','ieeeRecordNumber']].map(([label,key])=><div className="detail" key={key}><small>{label}</small><strong>{String(conference?.[key] ?? '—')}</strong></div>)}</div>}</div>}
      </div>
    </main>
    {modal && <RecordModal kind={modal} editing={editing} conference={conference} saving={saving} onClose={() => {setModal(null);setEditing(null)}} onSubmit={modal === 'conference' ? saveConference : saveRecord}/>}
  </div>
}

function messageOf(error: unknown) {
  return error instanceof Error ? error.message : 'Something went wrong. Check your Firebase configuration and Firestore rules.'
}

function Login({ onLogin, error }: { onLogin: (email: string, password: string) => Promise<void>; error: string }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [busy, setBusy] = useState(false)
  const [localError, setLocalError] = useState('')
  async function submit(e: FormEvent) {
    e.preventDefault(); setBusy(true); setLocalError('')
    try { await onLogin(email.trim(), password) } catch (err) { setLocalError(messageOf(err)) } finally { setBusy(false) }
  }
  return <div className="login-screen"><div className="login-art"><div className="brand-mark large">IC</div><span className="eyebrow light">11TH INTERNATIONAL CONFERENCE</span><h1>ICSC 2027</h1><p>Signal Processing & Communication</p><div className="login-line"/></div><form className="login-card" onSubmit={submit}><div className="login-icon"><ShieldCheck/></div><span className="eyebrow">ADMINISTRATOR PORTAL</span><h2>Welcome back</h2><p>Sign in with your authorised conference admin account.</p>{(localError || error) && <div className="alert error">{localError || error}</div>}<label>Email address<input type="email" required value={email} onChange={e => setEmail(e.target.value)} placeholder="admin@example.com"/></label><label>Password<input type="password" required value={password} onChange={e => setPassword(e.target.value)} placeholder="Your password"/></label><button className="button primary full" disabled={busy}>{busy ? 'Signing in…' : 'Sign in securely'}</button><small className="login-foot">Access is restricted to active administrators.</small></form></div>
}

function RecordModal({ kind, editing, conference, saving, onClose, onSubmit }: {
  kind: ManagedSection | 'conference'; editing: RecordItem | null;
  conference: Record<string, unknown> | null; saving: boolean;
  onClose: () => void; onSubmit: (e: FormEvent<HTMLFormElement>) => void;
}) {
  const fields = kind === 'conference'
    ? [
      {key:'title',label:'App title',type:'text'}, {key:'conferenceName',label:'Conference name',type:'text'},
      {key:'venue',label:'Venue',type:'text'}, {key:'startDate',label:'Start date',type:'text'},
      {key:'endDate',label:'End date',type:'text'}, {key:'website',label:'Official website',type:'url'},
      {key:'ieeeRecordNumber',label:'IEEE record number',type:'text'},
    ]
    : configs[kind].fields
  const source = kind === 'conference' ? conference : editing
  return <div className="modal-backdrop" onMouseDown={e => {if(e.target === e.currentTarget) onClose()}}><form className="modal" onSubmit={onSubmit}><div className="modal-head"><div><span className="eyebrow">ICSC 2027 / CONTENT</span><h2>{kind === 'conference' ? 'Edit conference details' : `${editing ? 'Edit' : 'Add'} ${configs[kind].title}`}</h2></div><button type="button" className="icon-button" onClick={onClose}><X/></button></div><div className="form-fields">{fields.map(field=><label key={field.key}>{field.label}{field.type === 'textarea' ? <textarea name={field.key} required defaultValue={String(source?.[field.key] ?? '')} rows={4}/> : <input name={field.key} type={field.type} required={field.key !== 'photoUrl'} defaultValue={String(source?.[field.key] ?? '')}/>}</label>)}{kind !== 'conference' && <label className="check-label"><input type="checkbox" name="isPublished" defaultChecked={editing ? editing.isPublished !== false : true}/> Publish this content</label>}</div><div className="modal-actions"><button type="button" className="button secondary" onClick={onClose}>Cancel</button><button className="button primary" disabled={saving}>{saving ? 'Saving…' : 'Save changes'}</button></div></form></div>
}