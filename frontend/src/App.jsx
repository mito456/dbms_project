import React, { useState, useEffect } from 'react';
import { 
  Search, BookOpen, Users, Calendar, UserCheck, 
  Sparkles, Activity, PlusCircle, LogOut, ArrowRight, CheckCircle2, Sliders, Database
} from 'lucide-react';
import { apiRequest } from './services/api';

export default function App() {
  const [activeTab, setActiveTab] = useState('search');
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('openscholar_user');
    return saved ? JSON.parse(saved) : null;
  });

  // Global Metadata
  const [stats, setStats] = useState(null);
  const [topics, setTopics] = useState([]);

  // Semantic Search State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedTopic, setSelectedTopic] = useState('');
  const [minSimilarity, setMinSimilarity] = useState(0.5);
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);

  // Recommendations State
  const [collaborators, setCollaborators] = useState([]);
  const [conferences, setConferences] = useState([]);
  const [loadingRecs, setLoadingRecs] = useState(false);

  // Publications List State
  const [allPublications, setAllPublications] = useState([]);
  const [loadingPubs, setLoadingPubs] = useState(false);

  // Researcher Profile & Edit State
  const [myProfile, setMyProfile] = useState(null);
  const [editBio, setEditBio] = useState('');
  const [editInstitution, setEditInstitution] = useState('');
  const [saveProfileSuccess, setSaveProfileSuccess] = useState(false);

  // New Publication Modal State
  const [showPubModal, setShowPubModal] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [newAbstract, setNewAbstract] = useState('');
  const [newDate, setNewDate] = useState(new Date().toISOString().split('T')[0]);
  const [newDoi, setNewDoi] = useState('');
  const [newPubSuccess, setNewPubSuccess] = useState(false);

  // Auth Dialog State
  const [showAuthModal, setShowAuthModal] = useState(false);
  const [authEmail, setAuthEmail] = useState('ml.zhou@shanghai-tech.edu');
  const [authPassword, setAuthPassword] = useState('password');
  const [authError, setAuthError] = useState('');

  // Activity Logs
  const [activityLogs, setActivityLogs] = useState([]);

  // Load initial global data
  useEffect(() => {
    fetchStats();
    fetchTopics();
    fetchPublications();
    fetchLogs();
  }, []);

  // When user changes or recommendations tab opened
  useEffect(() => {
    if (user && activeTab === 'recommendations') {
      fetchRecommendations();
    }
    if (user && activeTab === 'profile') {
      fetchProfile();
    }
  }, [user, activeTab]);

  async function fetchStats() {
    try {
      const data = await apiRequest('/meta/stats');
      setStats(data);
    } catch (e) {
      console.error(e);
    }
  }

  async function fetchTopics() {
    try {
      const data = await apiRequest('/meta/topics');
      setTopics(data);
    } catch (e) {
      console.error(e);
    }
  }

  async function fetchPublications() {
    setLoadingPubs(true);
    try {
      const data = await apiRequest('/publications?limit=25');
      setAllPublications(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingPubs(false);
    }
  }

  async function fetchLogs() {
    try {
      const data = await apiRequest('/meta/activity-logs?limit=15');
      setActivityLogs(data);
    } catch (e) {
      console.error(e);
    }
  }

  async function handleSemanticSearch(e) {
    if (e) e.preventDefault();
    if (!searchQuery.trim()) return;

    setIsSearching(true);
    try {
      const payload = {
        query: searchQuery,
        limit: 10,
        min_similarity: parseFloat(minSimilarity),
        ...(selectedTopic ? { topic_id: parseInt(selectedTopic) } : {})
      };
      const data = await apiRequest('/publications/search/semantic', {
        method: 'POST',
        body: JSON.stringify(payload)
      });
      setSearchResults(data);
      fetchLogs(); // refresh activity
    } catch (err) {
      alert(`Search error: ${err.message}`);
    } finally {
      setIsSearching(false);
    }
  }

  async function fetchRecommendations() {
    setLoadingRecs(true);
    try {
      const [collabs, confs] = await Promise.all([
        apiRequest('/recommendations/collaborators?limit=6'),
        apiRequest('/recommendations/conferences?limit=6')
      ]);
      setCollaborators(collabs);
      setConferences(confs);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingRecs(false);
    }
  }

  async function fetchProfile() {
    try {
      const data = await apiRequest('/researchers/me');
      setMyProfile(data);
      setEditBio(data.bio || '');
      setEditInstitution(data.institution || '');
    } catch (e) {
      console.error(e);
    }
  }

  async function handleSaveProfile(e) {
    e.preventDefault();
    try {
      const data = await apiRequest('/researchers/me', {
        method: 'PUT',
        body: JSON.stringify({
          bio: editBio,
          institution: editInstitution
        })
      });
      setMyProfile(data);
      setSaveProfileSuccess(true);
      setTimeout(() => setSaveProfileSuccess(false), 3000);
    } catch (err) {
      alert(err.message);
    }
  }

  async function handleLogin(e) {
    e.preventDefault();
    setAuthError('');
    try {
      const data = await apiRequest('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email: authEmail, password: authPassword })
      });
      localStorage.setItem('openscholar_token', data.access_token);
      localStorage.setItem('openscholar_user', JSON.stringify(data));
      setUser(data);
      setShowAuthModal(false);
      fetchStats();
      fetchLogs();
    } catch (err) {
      setAuthError(err.message || 'Login failed. Use password: "password"');
    }
  }

  function handleLogout() {
    localStorage.removeItem('openscholar_token');
    localStorage.removeItem('openscholar_user');
    setUser(null);
    setMyProfile(null);
  }

  async function handleCreatePublication(e) {
    e.preventDefault();
    try {
      await apiRequest('/publications', {
        method: 'POST',
        body: JSON.stringify({
          title: newTitle,
          abstract: newAbstract,
          publication_date: newDate,
          doi: newDoi || null
        })
      });
      setNewPubSuccess(true);
      fetchPublications();
      fetchStats();
      fetchLogs();
      setTimeout(() => {
        setNewPubSuccess(false);
        setShowPubModal(false);
        setNewTitle('');
        setNewAbstract('');
      }, 1500);
    } catch (err) {
      alert(err.message);
    }
  }

  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '32px' }}>
          <div style={{
            background: 'var(--gradient-brand)',
            width: '38px',
            height: '38px',
            borderRadius: '10px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 0 15px rgba(6, 182, 212, 0.4)'
          }}>
            <Sparkles size={20} color="#fff" />
          </div>
          <div>
            <h2 style={{ fontSize: '1.1rem', fontWeight: 800, letterSpacing: '-0.02em' }}>OpenScholar</h2>
            <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>Intelligence Engine</p>
          </div>
        </div>

        <nav style={{ flex: 1 }}>
          <button 
            className={`nav-btn ${activeTab === 'search' ? 'active' : ''}`}
            onClick={() => setActiveTab('search')}
          >
            <Search size={18} />
            <span>Semantic Search</span>
          </button>

          <button 
            className={`nav-btn ${activeTab === 'recommendations' ? 'active' : ''}`}
            onClick={() => {
              if (!user) setShowAuthModal(true);
              else setActiveTab('recommendations');
            }}
          >
            <Sparkles size={18} />
            <span>Smart Recommendations</span>
          </button>

          <button 
            className={`nav-btn ${activeTab === 'publications' ? 'active' : ''}`}
            onClick={() => setActiveTab('publications')}
          >
            <BookOpen size={18} />
            <span>All Publications</span>
          </button>

          <button 
            className={`nav-btn ${activeTab === 'profile' ? 'active' : ''}`}
            onClick={() => {
              if (!user) setShowAuthModal(true);
              else setActiveTab('profile');
            }}
          >
            <UserCheck size={18} />
            <span>Researcher Profile</span>
          </button>

          <button 
            className={`nav-btn ${activeTab === 'activity' ? 'active' : ''}`}
            onClick={() => {
              fetchLogs();
              setActiveTab('activity');
            }}
          >
            <Activity size={18} />
            <span>MongoDB Activity Log</span>
          </button>
        </nav>

        {/* User Status in Sidebar */}
        <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: '16px' }}>
          {user ? (
            <div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: 600, color: '#fff' }}>{user.name}</span>
                <span className="badge badge-cyan">{user.role}</span>
              </div>
              <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)', marginBottom: '12px', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                {user.email}
              </p>
              <button 
                onClick={handleLogout}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  background: 'transparent',
                  border: 'none',
                  color: 'var(--text-faint)',
                  fontSize: '0.85rem',
                  cursor: 'pointer'
                }}
              >
                <LogOut size={14} /> Sign out
              </button>
            </div>
          ) : (
            <button className="btn-primary" style={{ width: '100%' }} onClick={() => setShowAuthModal(true)}>
              Sign In / Register
            </button>
          )}
        </div>
      </aside>

      {/* Main View Area */}
      <main className="main-content">
        {/* Header bar with quick metrics */}
        <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '32px' }}>
          <div>
            <h1 style={{ fontSize: '1.9rem', marginBottom: '6px' }}>
              {activeTab === 'search' && "Vector Semantic Intelligence"}
              {activeTab === 'recommendations' && "AI Collaborator & Conference Intelligence"}
              {activeTab === 'publications' && "Curated Research Repository"}
              {activeTab === 'profile' && "Researcher Identity & Research Interests"}
              {activeTab === 'activity' && "Distributed Audit & Activity Stream"}
            </h1>
            <p style={{ color: 'var(--text-muted)', fontSize: '0.95rem' }}>
              Powered by PostgreSQL <code style={{ color: 'var(--accent-cyan)' }}>pgvector</code> and <code style={{ color: 'var(--accent-purple)' }}>BAAI/bge-base-en-v1.5</code> 768-D Embeddings
            </p>
          </div>

          <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
            {user && (
              <button 
                className="btn-primary" 
                style={{ padding: '10px 16px', fontSize: '0.9rem' }}
                onClick={() => setShowPubModal(true)}
              >
                <PlusCircle size={16} /> Publish Paper
              </button>
            )}

            {stats && (
              <div style={{ display: 'flex', gap: '12px' }}>
                <div className="glass-panel" style={{ padding: '8px 16px', textAlign: 'center' }}>
                  <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#38bdf8' }}>{stats.publications}</div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-faint)', textTransform: 'uppercase' }}>Papers</div>
                </div>
                <div className="glass-panel" style={{ padding: '8px 16px', textAlign: 'center' }}>
                  <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#a855f7' }}>{stats.researchers}</div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-faint)', textTransform: 'uppercase' }}>Scholars</div>
                </div>
                <div className="glass-panel" style={{ padding: '8px 16px', textAlign: 'center' }}>
                  <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#10b981' }}>{stats.conferences}</div>
                  <div style={{ fontSize: '0.7rem', color: 'var(--text-faint)', textTransform: 'uppercase' }}>Conferences</div>
                </div>
              </div>
            )}
          </div>
        </header>

        {/* TAB 1: VECTOR SEMANTIC SEARCH */}
        {activeTab === 'search' && (
          <div className="animate-fade-in">
            <div className="glass-panel" style={{ padding: '28px', marginBottom: '32px' }}>
              <form onSubmit={handleSemanticSearch}>
                <div style={{ display: 'flex', gap: '12px', marginBottom: '20px' }}>
                  <div style={{ position: 'relative', flex: 1 }}>
                    <Search size={18} style={{ position: 'absolute', left: '16px', top: '15px', color: 'var(--text-muted)' }} />
                    <input 
                      type="text"
                      className="input-field"
                      style={{ paddingLeft: '44px', fontSize: '1.05rem' }}
                      placeholder="Search publications by research concept, e.g. 'adaptive vector indexing or post-quantum handshakes'..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                    />
                  </div>
                  <button type="submit" className="btn-primary" disabled={isSearching}>
                    {isSearching ? "Vectorizing..." : "Semantic Search"}
                  </button>
                </div>

                {/* Filter Controls */}
                <div style={{ display: 'flex', gap: '24px', alignItems: 'center', flexWrap: 'wrap', fontSize: '0.88rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Sliders size={16} color="var(--accent-cyan)" />
                    <label style={{ color: 'var(--text-muted)' }}>Discipline / Topic:</label>
                    <select 
                      className="input-field" 
                      style={{ width: 'auto', padding: '6px 12px' }}
                      value={selectedTopic}
                      onChange={(e) => setSelectedTopic(e.target.value)}
                    >
                      <option value="">All Research Topics</option>
                      {topics.map(t => (
                        <option key={t.topic_id} value={t.topic_id}>{t.name} ({t.category})</option>
                      ))}
                    </select>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <label style={{ color: 'var(--text-muted)' }}>Min Similarity:</label>
                    <input 
                      type="range" 
                      min="0" 
                      max="0.9" 
                      step="0.05"
                      value={minSimilarity}
                      onChange={(e) => setMinSimilarity(e.target.value)}
                    />
                    <span style={{ fontWeight: 600, color: 'var(--accent-cyan)' }}>{Math.round(minSimilarity * 100)}%</span>
                  </div>

                  <div style={{ color: 'var(--text-faint)', marginLeft: 'auto' }}>
                    Using pgvector <code style={{ color: '#38bdf8' }}>embedding &lt;=&gt; query_vector</code> Cosine Metric
                  </div>
                </div>
              </form>
            </div>

            {/* Results Display */}
            {searchResults.length > 0 && (
              <div>
                <h3 style={{ fontSize: '1.2rem', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Sparkles size={18} color="var(--accent-cyan)" />
                  Top Semantic Matches ({searchResults.length})
                </h3>

                <div style={{ display: 'grid', gap: '16px' }}>
                  {searchResults.map((paper) => (
                    <div key={paper.publication_id} className="glass-panel" style={{ padding: '24px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: '16px', marginBottom: '8px' }}>
                        <h4 style={{ fontSize: '1.15rem', color: '#fff', lineHeight: 1.4 }}>{paper.title}</h4>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexShrink: 0 }}>
                          <span className="badge badge-cyan" style={{ fontSize: '0.85rem' }}>
                            {(paper.similarity_score * 100).toFixed(1)}% Match
                          </span>
                        </div>
                      </div>

                      <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', marginBottom: '16px', lineHeight: 1.6 }}>
                        {paper.abstract}
                      </p>

                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '0.8rem', color: 'var(--text-faint)', borderTop: '1px solid var(--border-subtle)', paddingTop: '12px' }}>
                        <div>
                          <strong>Authors:</strong> {paper.authors || "Unassigned"}
                        </div>
                        <div>
                          <strong>Published:</strong> {paper.publication_date} | <strong>Topics:</strong> {paper.topics || "General"}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* TAB 2: SMART RECOMMENDATIONS */}
        {activeTab === 'recommendations' && (
          <div className="animate-fade-in">
            {loadingRecs ? (
              <div style={{ textAlign: 'center', padding: '60px' }}>
                <Sparkles size={32} color="var(--accent-cyan)" style={{ animation: 'spin 2s linear infinite' }} />
                <p style={{ marginTop: '12px', color: 'var(--text-muted)' }}>Calculating hybrid collaborator similarity & conference tracks...</p>
              </div>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '28px' }}>
                {/* Collaborators Column */}
                <div>
                  <h3 style={{ fontSize: '1.25rem', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Users size={20} color="var(--accent-cyan)" /> Recommended Collaborators
                  </h3>

                  <div style={{ display: 'grid', gap: '16px' }}>
                    {collaborators.map((c) => (
                      <div key={c.researcher_id} className="glass-panel" style={{ padding: '20px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                          <div>
                            <h4 style={{ fontSize: '1.05rem', color: '#fff' }}>{c.name}</h4>
                            <p style={{ fontSize: '0.8rem', color: 'var(--accent-cyan)' }}>{c.institution}</p>
                          </div>
                          <span className="badge badge-cyan">{(c.match_score * 100).toFixed(1)}% Alignment</span>
                        </div>

                        <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '12px' }}>
                          {c.bio || "Academic researcher in computational sciences."}
                        </p>

                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '12px' }}>
                          {c.shared_topics.map((t, idx) => (
                            <span key={idx} className="badge badge-purple" style={{ fontSize: '0.7rem' }}>{t}</span>
                          ))}
                        </div>

                        {c.top_matching_publication && (
                          <div style={{ fontSize: '0.75rem', color: 'var(--text-faint)', background: 'rgba(0,0,0,0.2)', padding: '6px 10px', borderRadius: '4px' }}>
                            Closest paper: <em>{c.top_matching_publication}</em>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>

                {/* Conferences Column */}
                <div>
                  <h3 style={{ fontSize: '1.25rem', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <Calendar size={20} color="var(--accent-purple)" /> Upcoming Conference Deadlines
                  </h3>

                  <div style={{ display: 'grid', gap: '16px' }}>
                    {conferences.map((conf) => (
                      <div key={conf.conference_id} className="glass-panel" style={{ padding: '20px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                          <div>
                            <h4 style={{ fontSize: '1.05rem', color: '#fff' }}>{conf.name}</h4>
                            <p style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{conf.location}</p>
                          </div>
                          <span className="badge badge-amber">
                            {conf.days_until_deadline} Days Left
                          </span>
                        </div>

                        <div style={{ fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '12px' }}>
                          <strong>Submission Deadline:</strong> {conf.submission_deadline}
                        </div>

                        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
                          {conf.matching_topics.map((t, idx) => (
                            <span key={idx} className="badge badge-emerald" style={{ fontSize: '0.7rem' }}>Track: {t}</span>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* TAB 3: ALL PUBLICATIONS */}
        {activeTab === 'publications' && (
          <div className="animate-fade-in">
            <div style={{ display: 'grid', gap: '16px' }}>
              {allPublications.map((pub) => (
                <div key={pub.publication_id} className="glass-panel" style={{ padding: '22px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: '8px' }}>
                    <h4 style={{ fontSize: '1.1rem', color: '#fff' }}>{pub.title}</h4>
                    <span style={{ fontSize: '0.8rem', color: 'var(--text-faint)' }}>{pub.publication_date}</span>
                  </div>
                  <p style={{ fontSize: '0.88rem', color: 'var(--text-muted)', marginBottom: '12px' }}>{pub.abstract}</p>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-faint)', display: 'flex', justifyContent: 'space-between' }}>
                    <span><strong>Authors:</strong> {pub.authors || "None"}</span>
                    <span><strong>Topics:</strong> {pub.topics || "General"}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* TAB 4: RESEARCHER PROFILE */}
        {activeTab === 'profile' && myProfile && (
          <div className="animate-fade-in" style={{ maxWidth: '800px' }}>
            <div className="glass-panel" style={{ padding: '32px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '28px' }}>
                <div style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '16px',
                  background: 'var(--gradient-brand)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  fontSize: '1.5rem',
                  fontWeight: 700
                }}>
                  {myProfile.name.charAt(0)}
                </div>
                <div>
                  <h3 style={{ fontSize: '1.4rem' }}>{myProfile.name}</h3>
                  <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>{myProfile.email}</p>
                  <span className="badge badge-emerald" style={{ marginTop: '6px' }}>
                    {myProfile.publications_count} Publications Authored
                  </span>
                </div>
              </div>

              <form onSubmit={handleSaveProfile}>
                <div style={{ marginBottom: '18px' }}>
                  <label style={{ display: 'block', fontSize: '0.88rem', color: 'var(--text-muted)', marginBottom: '6px' }}>
                    Institution / University
                  </label>
                  <input 
                    type="text" 
                    className="input-field"
                    value={editInstitution}
                    onChange={(e) => setEditInstitution(e.target.value)}
                  />
                </div>

                <div style={{ marginBottom: '24px' }}>
                  <label style={{ display: 'block', fontSize: '0.88rem', color: 'var(--text-muted)', marginBottom: '6px' }}>
                    Academic Biography & Focus
                  </label>
                  <textarea 
                    className="input-field"
                    rows="4"
                    value={editBio}
                    onChange={(e) => setEditBio(e.target.value)}
                  />
                </div>

                <div style={{ marginBottom: '24px' }}>
                  <label style={{ display: 'block', fontSize: '0.88rem', color: 'var(--text-muted)', marginBottom: '10px' }}>
                    Assigned Research Interests
                  </label>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                    {myProfile.topics.map((t) => (
                      <span key={t.topic_id} className="badge badge-purple" style={{ padding: '6px 12px' }}>
                        {t.name} ({t.interest_level})
                      </span>
                    ))}
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                  <button type="submit" className="btn-primary">
                    Update Profile
                  </button>
                  {saveProfileSuccess && (
                    <span style={{ color: 'var(--accent-emerald)', fontSize: '0.9rem', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <CheckCircle2 size={16} /> Profile changes saved!
                    </span>
                  )}
                </div>
              </form>
            </div>
          </div>
        )}

        {/* TAB 5: MONGODB ACTIVITY STREAM */}
        {activeTab === 'activity' && (
          <div className="animate-fade-in">
            <div className="glass-panel" style={{ padding: '24px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                <h3 style={{ fontSize: '1.2rem', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Database size={18} color="var(--accent-emerald)" /> MongoDB Activity Ledger
                </h3>
                <button className="btn-secondary" style={{ padding: '6px 14px', fontSize: '0.8rem' }} onClick={fetchLogs}>
                  Refresh Ledger
                </button>
              </div>

              <div style={{ display: 'grid', gap: '12px' }}>
                {activityLogs.map((log) => (
                  <div 
                    key={log.id} 
                    style={{
                      padding: '14px 18px',
                      background: 'rgba(0,0,0,0.25)',
                      borderRadius: '8px',
                      borderLeft: '3px solid var(--accent-cyan)',
                      fontSize: '0.85rem'
                    }}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                      <span style={{ fontWeight: 600, color: 'var(--accent-cyan)' }}>{log.action}</span>
                      <span style={{ color: 'var(--text-faint)', fontSize: '0.75rem' }}>{log.timestamp}</span>
                    </div>
                    <div style={{ color: 'var(--text-muted)' }}>
                      <strong>User:</strong> {log.user_email || "Anonymous"} ({log.role || "public"})
                    </div>
                    <pre style={{
                      marginTop: '6px',
                      fontFamily: 'var(--font-mono)',
                      fontSize: '0.75rem',
                      color: 'var(--text-faint)',
                      overflowX: 'auto'
                    }}>
                      {JSON.stringify(log.details, null, 2)}
                    </pre>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </main>

      {/* Auth Modal */}
      {showAuthModal && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0, 0, 0, 0.75)',
          backdropFilter: 'blur(8px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 50
        }}>
          <div className="glass-panel" style={{ width: '420px', padding: '32px' }}>
            <h3 style={{ fontSize: '1.4rem', marginBottom: '8px' }}>Sign In to OpenScholar</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem', marginBottom: '20px' }}>
              Select or enter researcher credentials to unlock recommendations and profile management.
            </p>

            {authError && (
              <div style={{ color: 'var(--accent-rose)', fontSize: '0.85rem', marginBottom: '16px', background: 'rgba(244, 63, 94, 0.1)', padding: '10px', borderRadius: '6px' }}>
                {authError}
              </div>
            )}

            <form onSubmit={handleLogin}>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '6px' }}>
                  Email Address
                </label>
                <input 
                  type="email"
                  className="input-field"
                  value={authEmail}
                  onChange={(e) => setAuthEmail(e.target.value)}
                  required
                />
              </div>

              <div style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '6px' }}>
                  Password (sample data: "password")
                </label>
                <input 
                  type="password"
                  className="input-field"
                  value={authPassword}
                  onChange={(e) => setAuthPassword(e.target.value)}
                  required
                />
              </div>

              <div style={{ display: 'flex', gap: '12px' }}>
                <button type="submit" className="btn-primary" style={{ flex: 1 }}>Sign In</button>
                <button type="button" className="btn-secondary" onClick={() => setShowAuthModal(false)}>Cancel</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Publish Paper Modal */}
      {showPubModal && (
        <div style={{
          position: 'fixed',
          inset: 0,
          background: 'rgba(0, 0, 0, 0.75)',
          backdropFilter: 'blur(8px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 50
        }}>
          <div className="glass-panel" style={{ width: '560px', padding: '32px' }}>
            <h3 style={{ fontSize: '1.4rem', marginBottom: '8px' }}>Submit New Research Paper</h3>
            <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem', marginBottom: '20px' }}>
              Submissions automatically trigger BGE vectorization and update nearest neighbor indices.
            </p>

            {newPubSuccess ? (
              <div style={{ color: 'var(--accent-emerald)', padding: '20px', textAlign: 'center', fontSize: '1.1rem' }}>
                <CheckCircle2 size={32} style={{ margin: '0 auto 12px' }} />
                Publication indexed & vector embedding generated!
              </div>
            ) : (
              <form onSubmit={handleCreatePublication}>
                <div style={{ marginBottom: '14px' }}>
                  <label style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '4px' }}>Title</label>
                  <input 
                    type="text" 
                    className="input-field" 
                    value={newTitle}
                    onChange={(e) => setNewTitle(e.target.value)}
                    placeholder="E.g., Scalable Graph Transformer for Drug Discovery"
                    required 
                  />
                </div>

                <div style={{ marginBottom: '14px' }}>
                  <label style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '4px' }}>Abstract</label>
                  <textarea 
                    className="input-field" 
                    rows="4" 
                    value={newAbstract}
                    onChange={(e) => setNewAbstract(e.target.value)}
                    placeholder="Detailed abstract..."
                    required 
                  />
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '24px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '4px' }}>Date</label>
                    <input 
                      type="date" 
                      className="input-field" 
                      value={newDate}
                      onChange={(e) => setNewDate(e.target.value)}
                      required 
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.85rem', color: 'var(--text-muted)', marginBottom: '4px' }}>DOI (Optional)</label>
                    <input 
                      type="text" 
                      className="input-field" 
                      value={newDoi}
                      onChange={(e) => setNewDoi(e.target.value)}
                      placeholder="10.1145/..."
                    />
                  </div>
                </div>

                <div style={{ display: 'flex', gap: '12px' }}>
                  <button type="submit" className="btn-primary" style={{ flex: 1 }}>Publish & Generate Vector</button>
                  <button type="button" className="btn-secondary" onClick={() => setShowPubModal(false)}>Cancel</button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
